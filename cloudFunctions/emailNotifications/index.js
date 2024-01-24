const functions = require('@google-cloud/functions-framework');

const { Firestore } = require('@google-cloud/firestore');

const { initializeApp, applicationDefault, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue, Filter } = require('firebase-admin/firestore');

initializeApp({
    credential: applicationDefault()
});

const db = getFirestore();

const Mailjet = require('node-mailjet');
const mailjet = Mailjet.apiConnect(
    "162141a78db3df0fb6895bb06d5fa51f",
    "e9706139849b92997bb89a372a4a4e3d"
);


functions.http('emailNotifications', async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');

    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'GET, POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type');
        res.set('Access-Control-Max-Age', '3600');
        res.status(204).send('');
    } else {
        try {
            const snapshot = await db.collection('tasks').get();
            const currentDate = new Date();
            const fourDaysFromNow = new Date();
            fourDaysFromNow.setDate(currentDate.getDate() + 3);

            const tasksWithDueDate = snapshot.docs
                .filter(doc => {
                    const dueDate = doc.data().due_to.toDate();
                    return dueDate < fourDaysFromNow;
                })
                .map(doc => ({ id: doc.id, ...doc.data() }));


            let message = "";
            tasksWithDueDate.map((item, index) => {
                message += item.title;
                message += " ";
                message += item.due_to.toDate().toDateString();
                message += "<br />";
            })

            const request = mailjet
                .post('send', { version: 'v3.1' })
                .request({
                    Messages: [
                        {
                            From: {
                                Email: "gcpprojekt@gmail.com",
                                Name: "GCP"
                            },
                            To: [
                                {
                                    Email: "htmlek@protonmail.com",
                                    Name: "TODO APP USER"
                                }
                            ],
                            Subject: "Przypomnienie o upływających terminach zadań!",
                            TextPart: "Yo",
                            HTMLPart: "<h3>Zadania z upływającym terminem:</h3><br />" + message
                        }
                    ]
                })
            request
                .then((result) => {
                    console.log(result.body)
                })
                .catch((err) => {
                    console.log(err)
                })
            res.status(200).send('E-mail wysłany pomyślnie');
        } catch (error) {
            console.error('Błąd podczas wysyłania e-maila:', error);
            res.status(500).send('Błąd podczas wysyłania e-maila');
        }
    }
});