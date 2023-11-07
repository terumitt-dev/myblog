const noticeElements = document.getElementsByClassName("notice");
const alertElements = document.getElementsByClassName("alert");
console.log(noticeElements);
console.log(alertElements);

if (noticeElements[0] === null && alertElements[0] === null) {
  modalDialog.style.display = "none";
}

const modalDialog = document.querySelector(".modal_dialog");
console.log(modalDialog);

modalDialog.style.display = "block";

if (noticeElements[0]) {
  modalDialog.appendChild(noticeElements[0]);
}

if (alertElements[0]) {
  modalDialog.appendChild(alertElements[0]);
}

modalDialog.querySelector(".close_button").addEventListener("click", () => {
  modalDialog.style.display = "none";
});
