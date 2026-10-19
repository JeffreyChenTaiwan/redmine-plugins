module RedmineAutoDonePercentage
  class Hooks < Redmine::Hook::ViewListener
    # 在 Issue 表單底部注入 JavaScript
    def view_issues_form_details_bottom(context={})
      # 獲取設定的狀態列表
      settings = Setting.plugin_redmine_auto_done_percentage
      auto_complete_statuses = []
      
      if settings.is_a?(Hash) && settings['auto_complete_statuses'].is_a?(Array)
        auto_complete_statuses = settings['auto_complete_statuses']
      end
      
      # 將狀態 ID 轉換為 JavaScript 陣列
      status_ids_json = auto_complete_statuses.to_json
      
      # 返回要注入的 HTML/JavaScript
      javascript_tag = <<-JS
        <script type="text/javascript">
          // 設定自動完成的狀態 ID
          window.autoCompleteStatusIds = #{status_ids_json};
          
          // Auto Done Percentage Script v5 - Keep It Simple
          (function() {
            'use strict';
            
            function isStatusInList(statusId, statusList) {
              if (!statusList || statusId === undefined || statusId === null) return false;
              for (var i = 0; i < statusList.length; i++) {
                if (statusList[i] == statusId) return true;
              }
              return false;
            }
            
            function attachAutoDoneListener() {
              var form = document.getElementById('issue-form');
              var statusSelect = document.getElementById('issue_status_id');
              var doneRatioInput = document.getElementById('issue_done_ratio');
              var autoCompleteStatuses = window.autoCompleteStatusIds || [];

              if (!form || !statusSelect || !doneRatioInput || autoCompleteStatuses.length === 0) {
                return;
              }
              
              var eventHandler = function() {
                var newStatusId = statusSelect.value;
                var currentRatio = parseInt(doneRatioInput.value) || 0;
                var newInList = isStatusInList(newStatusId, autoCompleteStatuses);
                
                var savedRatio = form.dataset.autoDoneSavedRatio;

                if (newInList && savedRatio === undefined) {
                  form.dataset.autoDoneSavedRatio = currentRatio;
                  doneRatioInput.value = 100;
                  doneRatioInput.dispatchEvent(new Event('change', { bubbles: true }));

                } else if (!newInList && savedRatio !== undefined) {
                  doneRatioInput.value = savedRatio;
                  delete form.dataset.autoDoneSavedRatio;
                  doneRatioInput.dispatchEvent(new Event('change', { bubbles: true }));
                }
              };
              
              // 移除可能存在的舊監聽器，再綁定新的，確保只有一個在運作
              if (window.autoDoneLastHandler) {
                statusSelect.removeEventListener('change', window.autoDoneLastHandler);
              }
              statusSelect.addEventListener('change', eventHandler);
              window.autoDoneLastHandler = eventHandler;
            }
            
            // 直接執行。無論是初次載入還是 AJAX 刷新，此腳本都會被執行。
            attachAutoDoneListener();

          })();
        </script>
      JS
      
      javascript_tag.html_safe
    end
  end
end
