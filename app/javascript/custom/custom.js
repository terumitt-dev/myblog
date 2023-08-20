document.addEventListener("DOMContentLoaded", function() {
  const elements = document.querySelectorAll(".notice, .alert");

  elements.forEach(function(element) {
    const noticeMessage = element.getAttribute("data-notice");
    const alertMessage = element.getAttribute("data-alert");

    if ((noticeMessage !== null && noticeMessage.trim() !== "") || (alertMessage !== null && alertMessage.trim() !== "")) {
      element.style.opacity = "1";

      setTimeout(function() {
        element.style.transition = "opacity 3s";
        element.style.opacity = "0";
      }, 2000);
    }
  });
});
