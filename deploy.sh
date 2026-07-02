#!/bin/bash
set -euo pipefail

echo "=== Deploy: Al Ahli Sports Center ==="

echo ""
echo "1. Pull latest code"
cd /home/alahlice/alahli
git pull origin main

echo ""
echo "2. Collect static files"
cd backend
python3 manage.py collectstatic --noinput
cd ..

echo ""
echo "3. Migrate database"
cd backend
python3 manage.py migrate --noinput
cd ..

echo ""
echo "4. Restart Passenger"
touch passenger_wsgi.py
echo "   Passenger restarted via passenger_wsgi.py touch"

echo ""
echo "5. Verify health"
sleep 2
curl -s https://alahlicenter.ly/api/health/ | python3 -m json.tool

echo ""
echo "=== Deploy complete ==="
echo "Clear your browser cache or test in incognito mode."
