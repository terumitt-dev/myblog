document.addEventListener("DOMContentLoaded", function() {
  const noticeElement = document.getElementById("notice").dataset.notice;
  const alertElement = document.getElementById("alert").dataset.alert;

  if (noticeElement.textContent.trim() !== "" || alertElement.textContent.trim() !== "") {
    noticeElement.style.opacity = "1";
    alertElement.style.opacity = "1";

    setTimeout(function() {
      noticeElement.style.transition = "opacity 3s";
      alertElement.style.transition = "opacity 3s";
      noticeElement.style.opacity = "0";
      alertElement.style.opacity = "0";
    }, 2000);
  }
});
