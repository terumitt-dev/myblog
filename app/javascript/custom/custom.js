const noticeElements = document.getElementsByClassName("notice");
const alertElements = document.getElementsByClassName("alert");
console.log(noticeElements);
console.log(alertElements);


setTimeout(() => {
  noticeElements[0].style.display = "block";
  alertElements[0].style.display = "block";
}, 5000);

// フラッシュメッセージを15秒かけてフェードアウトする
setTimeout(() => {
  noticeElements[0].style.opacity = 1;
  noticeElements[0].style.transition = "opacity 15s linear";
  noticeElements[0].style.opacity = 0;
  noticeElements[0].style.display = "none";

  alertElements[0].style.opacity = 1;
  alertElements[0].style.transition = "opacity 15s linear";
  alertElements[0].style.opacity = 0;
  alertElements[0].style.display = "none";
}, 10000);
