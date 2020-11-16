---
date: 2017-11-16T16:29:31
layout: post
tags: []
title: "Комп&#39;ютерний зір - дещо захопливе. Достатньо шести ..."
---
Комп&#39;ютерний зір - дещо захопливе. Достатньо шести рядків мовою Python3 і кілька пакунків вільного ПЗ, щоб отримати координати облич на фото.
cascade_path = \
    &#39;haarcascade_frontalface_default.xml&#39;
face_cascade = cv2.CascadeClassifier(cascade_path)
recognizer = cv2.face.LBPHFaceRecognizer_create(
    1, 8, 8, 8, 123)
gray = PIL.Image.open(image_path).convert(&#39;L&#39;)
image = numpy.array(gray, &#39;uint8&#39;)
faces = face_cascade.detectMultiScale(
    image, scaleFactor=1.1, minNeighbors=5, 
    minSize=(30, 30))поправив попереднє повідомлення, бо ще скажете, що брешу)