document.addEventListener('turbo:load', () => {
  let dialog = document.getElementById("dialog");
  let noticeElement = document.getElementById("notice");
  let alertElement = document.getElementById("alert");
  let closer = document.getElementById("closer");

  // Turbo Drive のページ読み込み時に実行されるため、
  // 要素が存在するか確認する必要がある
  if (dialog && noticeElement && alertElement && closer) {
    let noticeText = noticeElement.textContent.trim();
    let alertText = alertElement.textContent.trim();

    console.log("Notice:", noticeText);
    console.log("Alert:", alertText);

    if (noticeText || alertText) {
      dialog.classList.add("inview"); // CSS の `visibility: visible; opacity: 1;` を適用
    }

    closer.addEventListener("click", () => {
      dialog.classList.remove("inview");
    });

    // 3秒後に自動で非表示にする
    setTimeout(() => {
      dialog.classList.remove("inview");
    }, 5000);
  } else {
    console.log("必要な要素が見つかりませんでした。");
  }
});
