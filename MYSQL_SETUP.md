# 🗄️ MySQL Database Setup Guide

## 🎯 What You're Getting

A **centralized MySQL database** that will store all your data in the cloud, accessible from any device:

- ✅ **True multi-user**: All users share the same data
- ✅ **Real-time sync**: Changes appear instantly on all devices  
- ✅ **Persistent storage**: Data never lost
- ✅ **Scalable**: Handle hundreds of users
- ✅ **Professional**: Enterprise-grade database

## 🚀 Quick Setup (Railway - Recommended)

### Step 1: Deploy Backend
1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub
3. Click "Deploy from GitHub repo"
4. Connect your `attendance-zone-system` repository
5. Select the `backend` folder
6. Railway will auto-deploy your Node.js API

### Step 2: Add MySQL Database
1. In Railway dashboard → "Add Service"
2. Select "MySQL" 
3. Railway will create database and set environment variables
4. Your API will automatically connect

### Step 3: Get API URL
1. In Railway → Your backend service
2. Go to "Settings" → "Domains"
3. Copy your API URL (like `https://your-app.railway.app`)

### Step 4: Update Flutter App
1. Open `lib/services/mysql_service.dart`
2. Replace `baseUrl` with your Railway URL:
   ```dart
   static const String baseUrl = 'https://your-app.railway.app/api';
   ```

### Step 5: Deploy Updated Flutter App
```bash
git add .
git commit -m "🗄️ Add MySQL database integration"
git push
```

## 🎉 Result

Your app will now use MySQL database with:
- **Shared data** across all devices
- **Real-time updates** 
- **Professional reliability**
- **Unlimited scalability**

## 🔧 Alternative: Local Development

### Install MySQL Locally
```bash
# macOS
brew install mysql
brew services start mysql

# Create database
mysql -u root -p
CREATE DATABASE attendance_mauritius;
```

### Run Backend Locally
```bash
cd backend
npm install
npm start
```

### Update Flutter App
```dart
// In mysql_service.dart
static const String baseUrl = 'http://localhost:3000/api';
```

## 📊 Database Schema

Your MySQL database will have these tables:

### Users Table
- `user_id` (Primary Key)
- `username`, `email`, `password_hash`
- `full_name`, `role`, `assigned_constituencies`
- `is_active`, `created_at`, `last_login_at`

### Constituencies Table  
- `constituency_no` (Primary Key)
- `name`, `electoral_population`, `ethnic_majority`
- `created_at`

### Attendance Events Table
- `id` (Primary Key)
- `person_id`, `card_uid`, `zone_id`, `reader_id`
- `decision`, `reason_code`, `timestamp`
- `constituency_no`, `user_id`

## 🎯 Multi-User Benefits

With MySQL, your system becomes truly multi-user:

### Before (Hive)
- Data stored locally in each browser
- No sharing between devices
- Each browser = separate database

### After (MySQL)  
- Data stored centrally in cloud
- All devices share same database
- Real-time sync across all users
- Professional enterprise setup

## 💰 Costs

### Railway (Recommended)
- **Free tier**: Perfect for your use case
- **Paid**: $5/month if you exceed free limits
- **Includes**: MySQL database + API hosting

### PlanetScale + Heroku
- **Both free tiers**: Good for development
- **PlanetScale**: Free MySQL database
- **Heroku**: Free API hosting

## 🔍 Testing

After deployment, test these scenarios:

1. **Multi-device**: Login from different browsers/devices
2. **Real-time sync**: Create user on Device A, see it on Device B
3. **Data persistence**: Refresh browser, data remains
4. **Role-based access**: Different permissions work correctly

## 🆘 Troubleshooting

### API Connection Issues
- Check API URL in `mysql_service.dart`
- Verify Railway deployment status
- Check browser console for errors

### Database Connection Issues  
- Verify MySQL service is running in Railway
- Check environment variables are set
- Review Railway logs for errors

## 🎊 Success!

Once deployed, your **Attendance & Zone Access System** will be a professional, enterprise-grade application with:

- 🗄️ **MySQL database** in the cloud
- 👥 **True multi-user** functionality  
- 🌐 **Global accessibility**
- 📊 **Real-time data sync**
- 🔒 **Professional security**

Perfect for managing attendance across all 21 Mauritius constituencies! 🇲🇺
