// const opener = document.getElementById("opener");
// const dialog = document.getElementById("dialog");
// const closer = document.getElementById("closer");

// opener.addEventListener("click", () => {
//   dialog.classList.add("inview");
// }, false);

// closer.addEventListener("click", () => {
//   dialog.classList.remove("inview");
// }, false);

function displayFlashMessage(data) {
  const div = document.createElement('div');
  div.className = 'flash-message';
  div.textContent = data.message;

  const flashContainer = document.querySelector('.flash-message-container');
  flashContainer.appendChild(div);
  div.classList.add(data.message_type);

  //js側でstyleを設定（画面の中央に固定で配置する）
  flashContainer.style.position = 'fixed';
  flashContainer.style.top = '50%';
  flashContainer.style.left = '50%';
  flashContainer.style.opacity = 0.9;
  flashContainer.style.zIndex = 99;
  // jqueryのfadeOutメソッドで5秒後に非表示
  $(div).fadeOut(5000);
};
