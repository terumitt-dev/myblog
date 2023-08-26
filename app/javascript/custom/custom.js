document.addEventListener("DOMContentLoaded", function() {
  const noticeElements = document.querySelectorAll(".notice");
  const alertElements = document.querySelectorAll(".alert");

  console.log("noticeElements:", noticeElements);
  console.log("alertElements:", alertElements);

  noticeElements.forEach(function(noticeElement) {
    const noticeMessage = noticeElement.textContent.trim();
    console.log("noticeMessage:", noticeMessage);

    setTimeout(function() {
      noticeElement.style.transition = "opacity 3s";
      noticeElement.style.opacity = "0";
    }, 2000);
  });

  alertElements.forEach(function(alertElement) {
    const alertMessage = alertElement.textContent.trim();
    console.log("alertMessage:", alertMessage);

    setTimeout(function() {
      alertElement.style.transition = "opacity 3s";
      alertElement.style.opacity = "0";
    }, 2000);
  });
});
