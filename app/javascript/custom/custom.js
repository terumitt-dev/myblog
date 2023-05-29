document.addEventListener("DOMContentLoaded", function() {
  const noticeElement = document.querySelector(".green-text");
  const alertElement = document.querySelector(".red-text");

  if (noticeElement) {
    setTimeout(function() {
      noticeElement.style.display = "none";
    }, 5000);
  }

  if (alertElement) {
    setTimeout(function() {
      alertElement.style.display = "none";
    }, 5000);
  }
});