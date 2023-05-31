document.addEventListener("DOMContentLoaded", function() {
  const noticeElement = document.getElementById("notice");
  const alertElement = document.getElementById("alert");

  if (noticeElement.textContent.trim() !== "" || alertElement.textContent.trim() !== "") {
    setTimeout(function() {
      location.reload();
    }, 5000);
  }
});
