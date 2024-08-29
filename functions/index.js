const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onNewChatMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const chatId = context.params.chatId;
    const newMessage = snapshot.data();
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    const chatData = chatDoc.data();

    const tokens = [];
    for (let participant in chatData.participants) {
      if (participant !== newMessage.userId && !chatData.participants[participant].isChating && !chatData.participants[participant].optOutOfChatNotifications) {
        const userDoc = await admin.firestore().collection('users').doc(participant).get();
        const tokensSnapshot = await userDoc.ref.collection('tokens').get();
        tokensSnapshot.forEach(doc => {
          tokens.push(doc.data().token);
        });
      }
    }

    if (tokens.length > 0) {
      const payload = {
        notification: {
          title: 'New Message',
          body: newMessage.text,
        },
        data: {
          chatId: chatId,
        },
      };
      await admin.messaging().sendToDevice(tokens, payload);
    }
  });
exports.onNewPostOrReply = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snapshot, context) => {
    const post = snapshot.data();
    const postId = context.params.postId;
    let tokens = [];

    if (post.parentId === "0") {
      // New Forum Post
      const usersSnapshot = await admin.firestore().collection('users').get();
      usersSnapshot.forEach(async userDoc => {
        const userData = userDoc.data();
        if (userData.topics.some(topic => post.topics.includes(topic)) && !userData.optOutOfNewPostNotifications) {
          const tokensSnapshot = await userDoc.ref.collection('tokens').get();
          tokensSnapshot.forEach(doc => {
            tokens.push(doc.data().token);
          });
        }
      });
    } else {
      // Forum Reply
      const repliesSnapshot = await admin.firestore().collection('posts').where('parentId', '==', post.id).get();
      const uniqueUsers = new Set();
      repliesSnapshot.forEach(replyDoc => {
        const replyOwner = replyDoc.data().owner;
        if (replyOwner !== post.owner && !uniqueUsers.has(replyOwner)) {
          uniqueUsers.add(replyOwner);
        }
      });

      for (let userId of uniqueUsers) {
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (!userDoc.data().optOutOfReplyNotifications) {
          const tokensSnapshot = await userDoc.ref.collection('tokens').get();
          tokensSnapshot.forEach(doc => {
            tokens.push(doc.data().token);
          });
        }
      }
    }

    if (tokens.length > 0) {
      const payload = {
        notification: {
          title: 'New Forum Activity',
          body: post.title,
        },
        data: {
          postId: post.parentId === "0" ? postId : post.parentId,
        }
      };
      await admin.messaging().sendToDevice(tokens, payload);
    }
  });
exports.onConnectionRequest = functions.firestore
  .document('connectionRequests/{requestId}')
  .onCreate(async (snapshot, context) => {
    let tokens = [];
    const connectionRequest = snapshot.data();
    const userDoc = await admin.firestore().collection('users').doc(connectionRequest.to).get();

    if (!userDoc.data().optOutOfConnectionRequestNotifications) {
      const tokensSnapshot = await userDoc.ref.collection('tokens').get();
      tokensSnapshot.forEach(doc => {
        tokens.push(doc.data().token);
      });
      if(tokens.length > 0) {
        const payload = {
          notification: {
            title: 'New Connection Request',
            body: `You have a new connection request from ${connectionRequest.from}`,
          },
        };
        await admin.messaging().sendToDevice(tokens, payload);
      }
    }
  });
