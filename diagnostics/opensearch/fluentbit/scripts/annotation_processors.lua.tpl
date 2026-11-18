-- Filebeat processor-annotation emulation (co.elastic.logs/processors.*).
--
-- For tenants with 10+ annotated services. Reads each pod's annotations
-- LIVE, per record -- no service names listed anywhere, so a newly
-- annotated service works on its very next log line with zero redeploy.
-- Below 10 services, prefer the Match_Regex conf.d filter (generate-conf-d.sh)
-- instead: simpler, inspectable in /api/v1/metrics, no Annotations: On needed.
--
-- Delivered via ConfigMap (like conf.d), not baked into the image, so the
-- per-tenant decision of which path to use requires no image rebuild.
--
-- Loaded by tenant_extract.lua via a guarded dofile() -- see that file.
-- Requires Annotations: On in fluent-bit.conf (confirmed: K8S-Logging.Parser
-- and K8S-Logging.Exclude do NOT need it, but reading annotation CONTENT
-- from the record does).
--
-- Why this is Lua and not a conf.d Condition: confirmed directly against a
-- live cluster that Fluent Bit's `modify` filter honours Condition, but the
-- `parser` filter silently IGNORES it -- it decodes every record matching
-- Match regardless of Condition. That makes native filters unusable for
-- decode_json_fields specifically.
--
-- Called as: annotation_processor(record, pod_annotations, decoded)
--   record          -- the log record table, mutated in place
--   pod_annotations -- record.kubernetes.annotations BEFORE it is read (the
--                      caller must capture this prior to any rebuild that
--                      would drop it)
--   decoded         -- record.log_processed, i.e. the JSON the kubernetes
--                      filter's Merge_Log already parsed from the raw log
--                      line -- NOT re-parsed here
--
-- Annotations are read and discarded within this call; nothing here writes
-- kubernetes.annotations back into the record, so the raw annotation blob
-- never reaches OpenSearch (same reasoning tenant_extract.lua already
-- applies to log_processed itself).

local PROCESSORS_ANNOTATION_PREFIX = "co.elastic.logs/processors."

local function split_dot(s)
    local parts = {}
    local start = 1
    while true do
        local dot = s:find(".", start, true)
        if not dot then
            table.insert(parts, s:sub(start))
            break
        end
        table.insert(parts, s:sub(start, dot - 1))
        start = dot + 1
    end
    return parts
end

local function coerce_scalar(v)
    if v == "true" then return true end
    if v == "false" then return false end
    return v
end

local function set_nested(tbl, path, idx, value)
    local key = path[idx]
    if idx == #path then
        tbl[key] = value
    else
        if type(tbl[key]) ~= "table" then tbl[key] = {} end
        set_nested(tbl[key], path, idx + 1, value)
    end
end

-- Parses every "co.elastic.logs/processors.<N>.<type>.<rest>" annotation on
-- this pod into an ordered list (ascending N) of { type = <type>, cfg = <table> }.
-- N and the number of processors are unbounded and vary per pod -- nothing
-- here assumes a fixed index or a known set of services.
local function parse_processors(annotations)
    local by_index, indices = {}, {}
    for key, raw_value in pairs(annotations) do
        if key:sub(1, #PROCESSORS_ANNOTATION_PREFIX) == PROCESSORS_ANNOTATION_PREFIX then
            local rest = key:sub(#PROCESSORS_ANNOTATION_PREFIX + 1)
            local parts = split_dot(rest)
            if #parts >= 2 then
                local n, ptype = tonumber(parts[1]), parts[2]
                if n and ptype ~= "" then
                    local entry = by_index[n]
                    if not entry then
                        entry = { type = ptype, cfg = {} }
                        by_index[n] = entry
                        table.insert(indices, n)
                    end
                    if #parts > 2 then
                        local cfg_path = {}
                        for i = 3, #parts do table.insert(cfg_path, parts[i]) end
                        set_nested(entry.cfg, cfg_path, 1, coerce_scalar(raw_value))
                    end
                end
            end
        end
    end
    table.sort(indices)
    local ordered = {}
    for _, n in ipairs(indices) do table.insert(ordered, by_index[n]) end
    return ordered
end

-- Normalises a processor-config value that may be a bare scalar or an
-- indexed table-of-objects (fields.0.from/to, fields.1...) into one list.
local function normalize_list(v)
    if v == nil then return {} end
    if type(v) ~= "table" then return { v } end
    local keys = {}
    for k in pairs(v) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tonumber(a) < tonumber(b) end)
    local out = {}
    for _, k in ipairs(keys) do table.insert(out, v[k]) end
    return out
end

local function get_by_dotpath(tbl, path)
    local cur = tbl
    for _, p in ipairs(split_dot(path)) do
        if type(cur) ~= "table" then return nil end
        cur = cur[p]
    end
    return cur
end

local function set_by_dotpath(tbl, path, value)
    local parts = split_dot(path)
    local cur = tbl
    for i = 1, #parts - 1 do
        if type(cur[parts[i]]) ~= "table" then cur[parts[i]] = {} end
        cur = cur[parts[i]]
    end
    cur[parts[#parts]] = value
end

-- Filebeat `copy_fields`. Missing source field is always skipped (matches
-- ignore_missing=true, which is what every known annotation sets).
local function handle_copy_fields(record, cfg)
    for _, f in ipairs(normalize_list(cfg.fields)) do
        if type(f) == "table" and f.from and f.to then
            local val = get_by_dotpath(record, f.from)
            if val ~= nil then set_by_dotpath(record, f.to, val) end
        end
    end
end

-- Filebeat `decode_json_fields`. Source is the `decoded` argument
-- (log_processed) -- already parsed by the kubernetes filter's Merge_Log,
-- not re-parsed here. target nil/"" merges at record root; a non-empty
-- target nests under that key. overwrite_keys controls whether a decoded
-- key replaces an existing one of the same name (this is what turns the
-- outer "message" into the inner decoded value when the JSON itself has a
-- "message" key -- it does NOT blank message when the JSON has no such key).
local function handle_decode_json_fields(record, cfg, decoded)
    if type(decoded) ~= "table" then return end
    local overwrite = cfg.overwrite_keys == true
    local target = cfg.target
    if target == nil or target == "" then
        for k, v in pairs(decoded) do
            if overwrite or record[k] == nil then record[k] = v end
        end
    else
        if overwrite or record[target] == nil then record[target] = decoded end
    end
end

-- Add more Filebeat processor types here as real annotation sets need them.
-- This table is the only thing that grows as new processor types appear
-- across the 50+ services -- no per-service code anywhere.
local PROCESSORS = {
    copy_fields = handle_copy_fields,
    decode_json_fields = handle_decode_json_fields,
}

-- Applies every processor annotation on this pod, in order. Unsupported
-- types and handler errors are recorded ON THE RECORD (queryable in
-- OpenSearch) rather than silently skipped. At 50+ services this is the
-- only practical way to discover a processor type nobody implemented yet --
-- aggregate on _annotation_unsupported to see which types are missing,
-- ranked by how many documents hit them:
--
--   GET filebeat-fluentbit-*/_search
--   {"size":0,"aggs":{"gap":{"terms":{"field":"_annotation_unsupported"}}}}
return function(record, annotations, decoded)
    if type(annotations) ~= "table" then return end
    for _, p in ipairs(parse_processors(annotations)) do
        local handler = PROCESSORS[p.type]
        if handler then
            local ok, err = pcall(handler, record, p.cfg, decoded)
            if not ok then
                record["_annotation_processor_error"] = p.type .. ": " .. tostring(err)
            end
        else
            record["_annotation_unsupported"] = p.type
        end
    end
end
