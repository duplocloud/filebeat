local ALIAS = os.getenv("ALIAS") or "unknown"
local SVC_LEVEL = os.getenv("SERVICE_LEVEL_INDEX") or "no"
local HOSTNAME = os.getenv("HOSTNAME") or "unknown"
local INDEX_PREFIX = os.getenv("INDEX_PREFIX") or "filebeat-fluentbit-"
local TAG_PREFIX = "kube.var.log.containers."
local LOG_DIR = "/var/log/containers/"

local function freeze(t)
    return setmetatable(t, { __newindex = function() error("attempt to modify frozen table") end })
end
local AGENT = freeze({ name = HOSTNAME, type = "fluent-bit", version = "5.0.6", hostname = HOSTNAME })
local HOST = freeze({ name = HOSTNAME })
local INPUT = freeze({ type = "container" })

function extract_tenant_and_set_index(tag, timestamp, record)
    local k = record["kubernetes"]
    local tenant, tenant_id, container_name = "unknown", "", "unknown"

    if k then
        -- Extract tenant from labels
        local labels = k["labels"]
        if labels then
            local tname = labels["tenantname"] or ""
            if tname ~= "" then
                tenant = tname:gsub("^duploservices%-", "")
            end
            tenant_id = labels["tenantid"] or ""
        end

        -- Fallback: extract tenant from namespace
        if tenant == "unknown" and k["namespace_name"] then
            local t = k["namespace_name"]:match("^duploservices%-(.+)$")
            tenant = t or k["namespace_name"]
        end

        container_name = k["container_name"] or "unknown"

        -- Restructure kubernetes metadata + build container object
        record["kubernetes"] = {
            labels = labels,
            container = { name = k["container_name"], image = k["container_image"] },
            node = { hostname = k["host"], name = k["host"] },
            pod = { uid = k["pod_id"], name = k["pod_name"] },
            namespace = k["namespace_name"]
        }
        record["container"] = {
            id = k["docker_id"],
            image = { name = k["container_image"] },
            runtime = "containerd"
        }
    end

    -- Build index prefix
    if ALIAS ~= "unknown" and ALIAS ~= "" then
        record["index_prefix"] = ALIAS .. "-fb"
    elseif SVC_LEVEL == "yes" and container_name ~= "unknown" then
        record["index_prefix"] = INDEX_PREFIX .. container_name
    else
        record["index_prefix"] = INDEX_PREFIX:gsub("%-$", "")
    end

    -- Rename log -> message, build log file object, remove CRI partial flag
    record["message"] = record["log"]
    record["log_processed"] = nil
    record["_p"] = nil
    local filename = tag:sub(#TAG_PREFIX + 1)
    if filename ~= "" then
        record["log"] = { file = { path = LOG_DIR .. filename } }
    else
        record["log"] = nil
    end

    -- Omitted filebeat-only filler: datastream, tenantLevelIndex, ecs.version (always "unknown"/"1.6.0")

    -- Add nested objects
    if tenant ~= "unknown" then
        record["tenant"] = { name = tenant, id = tenant_id }
    end
    record["agent"] = AGENT
    record["host"] = HOST
    record["input"] = INPUT

    return 1, timestamp, record
end
