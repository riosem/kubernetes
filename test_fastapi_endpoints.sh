# Get the external IP
EXTERNAL_IP=$(kubectl get svc fastapi-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "External IP: $EXTERNAL_IP"
# Test endpoints (replace EXTERNAL-IP with actual IP)
echo "Testing FastAPI endpoints at http://$EXTERNAL_IP/"
echo ""
echo "Root endpoint:"
curl http://$EXTERNAL_IP/
echo ""
echo "Health endpoint:"
curl http://$EXTERNAL_IP/health
echo ""
echo "Users endpoint:"
curl http://$EXTERNAL_IP/users
echo ""
echo "Products endpoint:"
curl http://$EXTERNAL_IP/products
echo ""
echo "Orders endpoint:"
curl http://$EXTERNAL_IP/orders
echo ""
echo "Stats endpoint:"
curl http://$EXTERNAL_IP/stats

# Create a new user
echo ""
echo "Creating a new user:"
curl -X POST http://$EXTERNAL_IP/users \
  -H "Content-Type: application/json" \
  -d '{"username":"newuser","email":"newuser@example.com"}'