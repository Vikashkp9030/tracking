#### Objective:

Develop a Flutter app that tracks user location and sends it to Firebase even when the app is in the background or closed. The app should send location updates based on these conditions:

- 50 meters distance from the last location.
- 5 minutes since the last update.


#### Requirements:

## Location Tracking:
- Use location or geolocator to track user location.
- Send location updates to Firebase (Firestore or Realtime Database) when:
    - 50 meters distance from previous location.
    - 5 minutes since last update.

## Firebase Integration:
Store location (latitude, longitude, timestamp) in Firebase.


Structured data example:

```
{
  "device_id": "device_id",
  "latitude": 12.34567,
  "longitude": 76.54321,
  "timestamp": "2025-01-01T12:00:00Z"
}
```

## Background Location Tracking:
Use flutter_background_geolocation (or similar) to track location in the background or when the app is closed.
UI:
- Display current latitude, longitude, and timestamp.
- Button to simulate manual location refresh.

## Permissions:
- Request location and background task permissions for Android and iOS.

## Deliverables:

- Source Code: Complete Flutter project with clear comments.
- Setup Instructions: Guide for Firebase setup and permissions.
- Testing Instructions: Steps to test on a real device.
- Documentation: Brief overview of app architecture, location handling, and Firebase integration.

### Bonus (Optional):
- Geofencing for location-based updates.
- Stop updates if user is stationary for a defined time.
