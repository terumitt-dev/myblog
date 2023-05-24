document.addEventListener("DOMContentLoaded", function() {
  var messageElement = document.getElementById("message");
  if (messageElement) {
    setTimeout(function() {
      messageElement.style.display = "none";
    }, 5000);
  }
});
