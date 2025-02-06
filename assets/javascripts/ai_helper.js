class AiHelper {
  ai_helper_urls = {};
  page_info = {
    additional_info: {}
  };
  local_storage_key = "aihelper-fold-flag";

  set_form_handlers = function () {
    // フォームのデフォルトのsubmit動作を防ぐ
    var form = $("#ai_helper_chat_form");
    form.on("submit", function (e) {
      e.preventDefault();
      submitAction();
    });

    // submitAction関数 - Ajax送信の例
    function submitAction() {
      $("#ai_helper_controller_name").val(ai_helper.page_info["controller_name"]);
      $("#ai_helper_action_name").val(ai_helper.page_info["action_name"]);
      $("#ai_helper_content_id").val(ai_helper.page_info["content_id"]);
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
        success: function (response) {
          $("#aihelper-chat-conversation").html(response);
          $("#ai-helper-loader-area").show();
          $("#ai_helper_chat_form")[0].reset();

          $("#aihelper-chat-conversation").scrollTop(
            $("#aihelper-chat-conversation")[0].scrollHeight
          );
          ai_helper.call_llm();
        },
        error: function (xhr, status, error) {
          console.error("Error:", error);
        }
      });
    }

    // textareaのキーイベント処理
    $("#ai_helper_chat_input").on("keydown", function (e) {
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

  call_llm = function () {
    const url = ai_helper_urls.call_llm;
    const data = JSON.stringify(this.page_info);
    const xhr = new XMLHttpRequest();
    xhr.open('POST', url, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    const csrfToken = $('meta[name="csrf-token"]').attr('content');
    xhr.setRequestHeader('X-CSRF-Token', csrfToken);

    // responseTypeを'text'に設定
    xhr.responseType = 'text';

    const parser = new AiHelperMarkdownParser();


    let fullResponse = '';
    let buffer = '';
    let lastProcessedIndex = 0;

    xhr.onprogress = function (event) {
      const text = xhr.responseText.substring(lastProcessedIndex);
      lastProcessedIndex = xhr.responseText.length;
      // console.log('onprogress:', text);
      buffer += text;

      // Server-Sent Eventsからデータを抽出
      const matches = buffer.match(/^data: (.+?)\n\n/gm);
      if (matches) {
        matches.forEach(match => {
          try {
            const dataStr = match.replace(/^data: /, '').trim();
            const data = JSON.parse(dataStr);

            // チャンクからコンテンツを取得
            const content = data.choices[0]?.delta?.content;
            if (content) {
              fullResponse += content;
              $('#aihelper_last_message').html(parser.parse(fullResponse));
              $("#aihelper-chat-conversation").scrollTop(
                $("#aihelper-chat-conversation")[0].scrollHeight
              );
            }
            if (data.choices[0]?.finish_reason === 'stop') {
              // $('#aihelper_last_message').text('AIが返信しました');
              $("#ai-helper-loader-area").hide();
              ai_helper.reload_chat();
            }
          } catch (e) {
            console.error('パースエラー:', e);
          }

          // バッファから処理済みデータを削除
          buffer = buffer.replace(match, '');
        });
        // buffer = '';
      }
    };

    xhr.onerror = function () {
      $('#aihelper_last_message').text('エラーが発生しました');
    };

    xhr.onload = function () {
      if (xhr.status !== 200) {
        $('#aihelper_last_message').text(`エラー: ${xhr.status} ${xhr.statusText}`);
      }
    };

    // リクエストボディの準備
    const requestBody = data;

    // リクエスト送信
    xhr.send(requestBody);

  };

  reload_chat = function () {
    var chatArea = $("#aihelper-chat-conversation");
    $.ajax({
      url: ai_helper_urls.reload,
      type: "GET",
      success: function (data) {
        chatArea.html(data);
        chatArea.scrollTop(chatArea[0].scrollHeight);
      },
      error: function (xhr, status, error) {
        console.error("Failed to reload chat conversation:", error);
      }
    });
  };

  load_history() {
    $.ajax({
      url: ai_helper_urls.history,
      type: "GET",
      success: function (data) {
        $("#aihelper-history").html(data);
      },
      error: function (xhr, status, error) {
        console.error("Failed to show chat history:", error);
      }
    });
  };

  clear_chat = function () {
    $.ajax({
      url: ai_helper_urls.clear,
      type: "GET",
      success: function (data) {
        ai_helper.close_dropdown_menu();
        ai_helper.reload_chat();
      },
      error: function (xhr, status, error) {
        console.error("Failed to clear chat conversation:", error);
      }
    });
  };

  set_hamberger_menu () {
    // ハンバーガーメニューのクリックイベント
    $(".aihelper-hamburger").click(function (event) {
      ai_helper.load_history();
      event.stopPropagation();
      $(this).toggleClass("active");
      $(".aihelper-dropdown-menu").slideToggle(300);
    });

    // ドロップダウンメニュー内のクリックイベントの伝播を停止
    $(".aihelper-dropdown-menu").click(function (event) {
      event.stopPropagation();
    });

    // ドキュメント全体のクリックイベント
    $(document).click(function () {
      ai_helper.close_dropdown_menu();
    });
  };

  close_dropdown_menu = function () {
    $(".aihelper-hamburger").removeClass("active");
    $(".aihelper-dropdown-menu").slideUp(300);
  };

  jump_to_history = function (event, url) {
    event.preventDefault();
    var chatArea = $("#aihelper-chat-conversation");
    $.ajax({
      url: url,
      type: "GET",
      success: function (data) {
        ai_helper.close_dropdown_menu();
        ai_helper.fold_chat(false);
        chatArea.html(data);
        chatArea.scrollTop(0);
      },
      error: function (xhr, status, error) {
        console.error("Failed to jump to history:", error);
      }
    });
  };

  delete_history = function (event, url) {
    event.preventDefault(); // デフォルトの遷移を防ぐ
    var chatArea = $("#aihelper-chat-conversation");
    $.ajax({
      url: url,
      type: "DELETE",
      success: function (data) {
        ai_helper.load_history();
        if (data["reload"]) {
          ai_helper.reload_chat();
        }
      },
      error: function (xhr, status, error) {
        console.error("Failed to jump to history:", error);
      }
    });
  };

  fold_chat = function (flag, disable_animation = false) {
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
    localStorage.setItem(this.local_storage_key, flag);
  };

  init_fold_flag = function () {
    var flag = localStorage.getItem(this.local_storage_key);
    if (flag === "true") {
      this.fold_chat(true, true);
    } else {
      this.fold_chat(false, true);
    }
  };
};

var ai_helper = new AiHelper();