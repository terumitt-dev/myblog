document.addEventListener("DOMContentLoaded", function() {
  const noticeElement = document.getElementById("notice");
  const alertElement = document.getElementById("alert");

  if (!(noticeElement.textContent.trim() === "" || alertElement.textContent.trim() === "")) {
  return;
  }
  
  setTimeout(function() {
    noticeElement.style.display = "none";
    alertElement.style.display = "none";
    location.reload();
  }, 5000);
});
