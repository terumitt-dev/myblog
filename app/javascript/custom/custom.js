// document.addEventListener("DOMContentLoaded", function() {
//   const noticeElement = document.getElementById("notice");
//   const alertElement = document.getElementById("alert");

//   if (noticeElement.innerHTML.trim() === "" || alertElement.innerHTML.trim() === "") {
//     setTimeout(function() {
//       noticeElement.style.display = "none";
//       alertElement.style.display = "none";
//       location.reload();
//     }, 5000);
//   }
// });

// document.addEventListener("DOMContentLoaded", function() {
//   const noticeElement = document.getElementById("notice");
//   const alertElement = document.getElementById("alert");

//   if (noticeElement.innerHTML.trim() !== null || alertElement.innerHTML.trim() !== null) {
//     setTimeout(function() {
//       noticeElement.style.display = "none";
//       alertElement.style.display = "none";
//       location.reload();
//     }, 5000);
//   }
// });

document.addEventListener("DOMContentLoaded", function() {
  const noticeElement = document.getElementById("notice");
  const alertElement = document.getElementById("alert");

  if (noticeElement.innerHTML.trim() == null && alertElement.innerHTML.trim() == null ) {
    return;
  }

  setTimeout(function() {
    noticeElement.style.display = "none";
    alertElement.style.display = "none";
    location.reload();
  }, 5000);
});
