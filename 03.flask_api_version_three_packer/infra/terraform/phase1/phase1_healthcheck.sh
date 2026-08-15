for i in {1..15}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$TEST_IP/healthz)
  echo "Attempt $i: $STATUS"
  [ "$STATUS" = "200" ] && echo "UP in ~${i}0 seconds!" && break
  sleep 10
done