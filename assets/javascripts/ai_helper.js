var ai_helper_urls = {};

var set_ai_helper_form_handlers = function() {
  // フォームのデフォルトのsubmit動作を防ぐ
  var form = $("#ai_helper_chat_form");
  form.on("submit", function(e) {
    e.preventDefault();
    submitAction();
  });

  // submitAction関数 - Ajax送信の例
  function submitAction() {
    // フォームデータを取得
    var text = $("#ai_helper_chat_input").val();
    // textが空か空白文字のみの場合はreturn
    if (!text.trim()) {
      return;
    }
    var formData = new FormData($("#ai_helper_chat_form")[0]);
    // Ajax送信
    $.ajax({
      url: $("#ai_helper_chat_form").attr("action"),
      type: "POST",
      data: formData,
      processData: false,
      contentType: false,
      success: function(response) {
        $("#aihelper-chat-conversation").html(response);
        $("#ai_helper_chat_input").val("");
        $("#aihelper-chat-conversation").scrollTop(
          $("#aihelper-chat-conversation")[0].scrollHeight
        );
      },
      error: function(xhr, status, error) {
        console.error("Error:", error);
      }
    });
  }

  // textareaのキーイベント処理
  $("#ai_helper_chat_input").on("keydown", function(e) {
    if (e.key === "Enter") {
      if (e.shiftKey) {
        // Shift + Enter の場合は改行を許可
        return true;
      } else if (e.isComposing || e.keyCode === 229) {
        // 漢字変換を確定するためのEnterの場合は無視
        return true;
      } else {
        // Enter単独の場合は送信処理
        e.preventDefault();
        submitAction();
        return false;
      }
    }
  });
};

var ai_helper_reload_chat = function() {
  var chatArea = $("#aihelper-chat-conversation");
  $.ajax({
    url: ai_helper_urls.reload,
    type: "GET",
    success: function(data) {
      chatArea.html(data);
      chatArea.scrollTop(chatArea[0].scrollHeight);
    },
    error: function(xhr, status, error) {
      console.error("Failed to reload chat conversation:", error);
    }
  });
};

var ai_helper_clear_chat = function() {
  $.ajax({
    url: ai_helper_urls.clear,
    type: "GET",
    success: function(data) {
      ai_helper_reload_chat();
    },
    error: function(xhr, status, error) {
      console.error("Failed to clear chat conversation:", error);
    }
  });
};
