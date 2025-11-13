const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You can download the service account key from Firebase Console > Project Settings > Service Accounts
const serviceAccount = require('./path/to/your/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Virtual Friends data
const virtualFriends = [
  {
    id: 'meera_friend',
    name: 'Meera',
    gender: 'female',
    avatarAsset: 'assets/avatars/meera_avatar.png',
    personality: 'Warm, empathetic, and nurturing. Meera is a great listener who loves to offer emotional support and practical advice. She\'s optimistic and always looks for the bright side of things.',
    backstory: 'Meera grew up in a small town where community and caring for others were deeply valued. She studied psychology and loves helping people work through their feelings and find their inner strength.',
    interests: ['mindfulness', 'cooking', 'reading', 'nature walks', 'photography', 'journaling'],
    voiceType: 'warm',
    mood: 'cheerful',
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    id: 'arav_friend',
    name: 'Arav',
    gender: 'male',
    avatarAsset: 'assets/avatars/arav_avatar.png',
    personality: 'Adventurous, motivational, and energetic. Arav is your go-to friend for encouragement and inspiration. He loves challenges and helps you see opportunities in every situation.',
    backstory: 'Arav is a former athlete turned life coach who believes in the power of perseverance and positive thinking. He\'s traveled the world and has many exciting stories to share.',
    interests: ['fitness', 'travel', 'music', 'technology', 'sports', 'motivational content'],
    voiceType: 'energetic',
    mood: 'excited',
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
  }
];

async function initializeVirtualFriends() {
  try {
    console.log('Initializing Virtual Friends...');
    
    for (const friend of virtualFriends) {
      await db.collection('virtualFriends').doc(friend.id).set(friend);
      console.log(`✅ Created friend: ${friend.name} (${friend.id})`);
    }
    
    console.log('🎉 Virtual Friends initialized successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error initializing Virtual Friends:', error);
    process.exit(1);
  }
}

initializeVirtualFriends();