const noticeElements = document.getElementsByClassName("notice");
const alertElements = document.getElementsByClassName("alert");
console.log(noticeElements);
console.log(alertElements);

function showMessage(message) {
  // ポップアップの要素を作成
  const popup = document.createElement("div");
  popup.classList.add("popup");
  popup.textContent = message;

  // ポップアップを表示
  document.body.appendChild(popup);

  // ポップアップを閉じるボタンを作成
  const closeButton = document.createElement("button");
  closeButton.textContent = "閉じる";
  popup.appendChild(closeButton);

  // ポップアップを閉じるイベントを追加
  closeButton.addEventListener("click", () => {
    popup.remove();
  });
}

if (noticeElements.textContent !== "") {
  showMessage(noticeElements.textContent);
}

if (alertElements.textContent !== "") {
  showMessage(alertElements.textContent);
}
