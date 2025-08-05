# shellcheck disable=SC2148
FROM="${1}"
TO="${2}"

DATETIME=$(date --iso-8601=minutes)
LIMIT=4

DATEFORMAT_IN='%Y-%m-%dT%H:%M:%S%z'
DATEFORMAT_OUT='%d.%m.%Y %H:%M'

FAHRPLAN=$(curl --silent --get \
  --data-urlencode "from=${FROM}" \
  --data-urlencode "to=${TO}" \
  --data-urlencode "datetime=${DATETIME}" \
  --data-urlencode "limit=4" \
  'https://transport.opendata.ch/v1/connections')

for i in $(seq 0 $((LIMIT - 1))); do
  echo "Verbindung #$((i + 1)):"
  # shellcheck disable=SC2312
  echo "${FAHRPLAN}" |
    jq -r ".connections[${i}].sections[][] | {
      Zug: (.category + .number | tostring),
      Gleis: .platform,
      Ort: .station.name,
      Abfahrt: (.departure | if . != null then (strptime(\"${DATEFORMAT_IN}\") | strftime(\"${DATEFORMAT_OUT}\")) end),
      Ankunft: (.arrival | if . != null then (strptime(\"${DATEFORMAT_IN}\") | strftime(\"${DATEFORMAT_OUT}\")) end)
    }" |
    mlr --ijson --opprint --barred cat |
    sed 's/null/    /g'
  echo ''
done
