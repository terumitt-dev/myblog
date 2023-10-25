const noticeElements = document.getElementsByClassName("notice");
const alertElements = document.getElementsByClassName("alert");

console.log(noticeElements);
console.log(alertElements);

function fadeout() {
  noticeElements[0].style.opacity = 1;
  noticeElements[0].style.transition = "opacity 3s linear";
  noticeElements[0].style.opacity = 0;
  noticeElements[0].style.display = "none";

  alertElements[0].style.opacity = 1;
  alertElements[0].style.transition = "opacity 3s linear";
  alertElements[0].style.opacity = 0;
  alertElements[0].style.display = "none";
}

setTimeout(fadeout, 5000);
