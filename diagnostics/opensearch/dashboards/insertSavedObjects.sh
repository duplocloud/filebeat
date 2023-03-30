set -eux
BASE_URL="http://127.0.0.1:5601${SERVER_BASEPATH}"
sleep 30
wait-for-url() {
    echo "InsertSavedObjects: Waiting for the service to be up"
    timeout -s TERM 120 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${0})" != "200" ]];\
    do echo "InsertSavedObjects: Waiting for ${0}" && sleep 2;\
    done' ${1}
    echo "InsertSavedObjects: OK!"

}
wait-for-url  ${BASE_URL}/status

createSavedObject(){
   curl -X POST "$BASE_URL/api/saved_objects/_import?overwrite=true" \
    -H "osd-xsrf: true" \
    --form file="@$f"
}

for f in SavedObjects/*.ndjson
do
        echo "InsertSavedObjects: Createing saved object for file - $f"
        # always "double quote" $f to avoid problems
        createSavedObject "$f"
done
