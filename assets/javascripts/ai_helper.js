var ai_helper_urls = {};
var ai_helper_page_info = {};

var set_ai_helper_form_handlers = function() {
  // フォームのデフォルトのsubmit動作を防ぐ
  var form = $("#ai_helper_chat_form");
  form.on("submit", function(e) {
    e.preventDefault();
    submitAction();
  });

  // submitAction関数 - Ajax送信の例
  function submitAction() {
    $("#ai_helper_controller_name").val(ai_helper_page_info["controller_name"]);
    $("#ai_helper_action_name").val(ai_helper_page_info["action_name"]);
    $("#ai_helper_content_id").val(ai_helper_page_info["content_id"]);
    // フォームデータを取得
    var text = $("#ai_helper_chat_input").val();
    // textが空か空白文字のみの場合はreturn
    if (!text.trim()) {
      return;
    }
    var formData = new FormData($("#ai_helper_chat_form")[0]);
    console.log(formData);
    // Ajax送信
    $.ajax({
      url: $("#ai_helper_chat_form").attr("action"),
      type: "POST",
      data: formData,
      processData: false,
      contentType: false,
      success: function(response) {
        $("#aihelper-chat-conversation").html(response);
        $("#ai-helper-loader-area").show();
        $("#ai_helper_chat_form")[0].reset();

        $("#aihelper-chat-conversation").scrollTop(
          $("#aihelper-chat-conversation")[0].scrollHeight
        );
        call_llm();
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

var call_llm = function() {
  data = {
    controller_name: ai_helper_page_info["controller_name"],
    action_name: ai_helper_page_info["action_name"],
    content_id: ai_helper_page_info["content_id"]
  };
  console.log(data);
  $.ajax({
    url: ai_helper_urls.call_llm,
    type: "POST",
    data: JSON.stringify(data),
    processData: false,
    contentType: "application/json",
    success: function(response) {
      $("#aihelper-chat-conversation").html(response);
      $("#aihelper-chat-conversation").scrollTop(
        $("#aihelper-chat-conversation")[0].scrollHeight
      );
    },
    error: function(xhr, status, error) {
      console.error("Error:", error);
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

var ai_helper_load_history = function() {
  $.ajax({
    url: ai_helper_urls.history,
    type: "GET",
    success: function(data) {
      $("#aihelper-history").html(data);
    },
    error: function(xhr, status, error) {
      console.error("Failed to show chat history:", error);
    }
  });
};

var ai_helper_clear_chat = function() {
  $.ajax({
    url: ai_helper_urls.clear,
    type: "GET",
    success: function(data) {
      ai_helper_close_dropdown_menu();
      ai_helper_reload_chat();
    },
    error: function(xhr, status, error) {
      console.error("Failed to clear chat conversation:", error);
    }
  });
};

var ai_helper_set_hamberger_menu = function() {
  // ハンバーガーメニューのクリックイベント
  $(".aihelper-hamburger").click(function(event) {
    ai_helper_load_history();
    event.stopPropagation();
    $(this).toggleClass("active");
    $(".aihelper-dropdown-menu").slideToggle(300);
  });

  // ドロップダウンメニュー内のクリックイベントの伝播を停止
  $(".aihelper-dropdown-menu").click(function(event) {
    event.stopPropagation();
  });

  // ドキュメント全体のクリックイベント
  $(document).click(function() {
    ai_helper_close_dropdown_menu();
  });
};

var ai_helper_close_dropdown_menu = function() {
  $(".aihelper-hamburger").removeClass("active");
  $(".aihelper-dropdown-menu").slideUp(300);
};

var ai_helper_jump_to_history = function(event, url) {
  event.preventDefault();
  var chatArea = $("#aihelper-chat-conversation");
  $.ajax({
    url: url,
    type: "GET",
    success: function(data) {
      ai_helper_close_dropdown_menu();
      ai_helper_fold_chat(false);
      chatArea.html(data);
      chatArea.scrollTop(0);
    },
    error: function(xhr, status, error) {
      console.error("Failed to jump to history:", error);
    }
  });
};

var ai_helper_delete_history = function(event, url) {
  event.preventDefault(); // デフォルトの遷移を防ぐ
  var chatArea = $("#aihelper-chat-conversation");
  $.ajax({
    url: url,
    type: "DELETE",
    success: function(data) {
      ai_helper_load_history();
      if (data["reload"]) {
        ai_helper_reload_chat();
      }
    },
    error: function(xhr, status, error) {
      console.error("Failed to jump to history:", error);
    }
  });
};

var ai_helper_fold_chat = function(flag, disable_animation = false) {
  var chatArea = $("#aihelper-foldable-area");
  var arrow_down = $("#aihelper-arrow-down");
  var arrow_left = $("#aihelper-arrow-left");
  if (flag) {
    if (disable_animation) {
      chatArea.hide();
    } else {
      chatArea.slideUp();
    }
    arrow_down.hide();
    arrow_left.show();
  } else {
    if (disable_animation) {
      chatArea.show();
    } else {
      chatArea.slideDown();
    }
    arrow_down.show();
    arrow_left.hide();
  }
  // フラグの値をローカルストレージに保存
  localStorage.setItem("aihelper-fold-flag", flag);
};

var ai_helper_init_fold_flag = function() {
  var flag = localStorage.getItem("aihelper-fold-flag");
  if (flag === "true") {
    ai_helper_fold_chat(true, true);
  } else {
    ai_helper_fold_chat(false, true);
  }
};
