import pymysql
# json 和 datetime 雖然匯入但未使用，如果確實不需要可以移除
# import json
# from datetime import datetime
import uuid
import logging # 建議使用 logging 而不是 print 來處理警告和錯誤

# --- 建議設定 Logging ---
# 在你的應用程式入口點設定一次即可，這裡作為範例
logging.basicConfig(level=logging.INFO, # 可以設為 DEBUG, INFO, WARNING, ERROR, CRITICAL
                    format='%(asctime)s - %(levelname)s - %(message)s')
# ------------------------

def add_member(
    id=None,
    age=None,
    height=None,
    weight=None,
    gender=None,
    sleep_start=None,
    sleep_end=None,
    medical_history=None,
    medical_history_other=None,
    sleep_quality=None,
    sleep_disturbance=None,
    sleep_disturbance_other=None,
    daily_conditions=None,
    daily_conditions_other=None,
    symptom=None,
    psychological_conditions=None,
    psychological_conditions_other=None,
    lifestyle=None,
    sports_status=None,
    sports_freq=None, # 這個參數可能是 list 或 None
    before_bed=None,
    before_bed_other=None
):
    """
    新增或更新會員資料。
    對於 array 類型的欄位 (如 medical_history, sports_freq 等),
    如果輸入是 list, 會轉換成逗號分隔的字串儲存。
    如果輸入是 None 或非 list, 會嘗試直接儲存 (或記錄警告)。
    """
    # 將所有參數整理成字典
    # 使用 locals() 可以簡化，但顯式列出更清晰，且避免包含非預期變數
    data = {
        'id': id,
        'age': age,
        'height': height,
        'weight': weight,
        'gender': gender,
        'sleep_start': sleep_start,
        'sleep_end': sleep_end,
        'medical_history': medical_history,
        'medical_history_other': medical_history_other,
        'sleep_quality': sleep_quality,
        'sleep_disturbance': sleep_disturbance,
        'sleep_disturbance_other': sleep_disturbance_other,
        'daily_conditions': daily_conditions,
        'daily_conditions_other': daily_conditions_other,
        'symptom': symptom,
        'psychological_conditions': psychological_conditions,
        'psychological_conditions_other': psychological_conditions_other,
        'lifestyle': lifestyle,
        'sports_status': sports_status,
        'sports_freq': sports_freq,
        'before_bed': before_bed,
        'before_bed_other': before_bed_other
    }

    connection = None # 初始化 connection，確保 finally 區塊能存取
    used_id = None # 儲存實際使用的 ID

    try:
        # --- 資料庫連線 ---
        # 建議將連線資訊移至設定檔或環境變數
        connection = pymysql.connect(
            host="10.140.0.6",
            user="transgeneai",
            password="Askbigwoo",
            database="transgene_ai",
            charset="utf8mb4",
            init_command="SET time_zone = '+08:00'",
            # autocommit=False # 預設就是 False, 手動 commit/rollback 更好
            connect_timeout=10 # 增加連線超時
        )
        logging.info("資料庫連線成功")

        # --- 處理 ID ---
        if not data.get('id'): # 使用 .get() 更安全
            data['id'] = str(uuid.uuid4())
            logging.info(f"未提供 ID，生成新 ID: {data['id']}")
        used_id = data['id']

        # --- 處理 Array 類型欄位 ---
        array_fields = [
            'medical_history', 'sleep_disturbance', 'daily_conditions',
            'symptom', 'psychological_conditions', 'lifestyle', 'sports_freq'
        ]
        for field in array_fields:
            # 檢查欄位是否存在且值不為 None
            if field in data and data[field] is not None:
                if isinstance(data[field], list):
                    # 將 list 轉為字串，確保元素也是字串
                    try:
                        data[field] = ','.join(map(str, data[field]))
                    except TypeError as e:
                        logging.warning(f"無法將欄位 '{field}' 的 list 轉換為字串: {e}，值: {data[field]}。將其設為 None。")
                        data[field] = None # 或者可以設為空字串 ''
                else:
                    # 如果值不是 None 也不是 list，記錄一個警告，因為這可能不是預期的類型
                    logging.warning(f"欄位 '{field}' 的值不是預期的 list 或 None，收到的類型是: {type(data[field])}，值: {data[field]}。將按原樣儲存。")
                    # 注意：如果資料庫欄位類型不匹配，這裡仍然可能導致 SQL 錯誤

        # --- 準備 SQL ---
        fields = list(data.keys()) # 直接從 data keys 取得所有欄位
        # 過濾掉值為 None 的欄位？通常不需要，讓資料庫處理 NULL
        # 不過如果確定某些欄位絕不能是 None 且必須有值，可以在這裡加入檢查

        # 確保欄位順序與值對應
        values = [data[field] for field in fields]
        placeholders = ', '.join(['%s'] * len(fields))
        field_names = ', '.join([f"`{field}`" for field in fields]) # 使用反引號避免關鍵字衝突

        # 建立更新字串，排除 id 欄位
        update_fields = [f"`{field}`=VALUES(`{field}`)" for field in fields if field != 'id']

        # 只有在有欄位需要更新時才加入 ON DUPLICATE KEY UPDATE 子句
        if update_fields:
            update_str = ', '.join(update_fields)
            sql = f"""
            INSERT INTO members ({field_names})
            VALUES ({placeholders})
            ON DUPLICATE KEY UPDATE {update_str}
            """
        else:
            # 如果只有 ID (可能是更新操作傳入，但其他都沒傳)，或者只有新生成的 ID
            # 這種情況下，ON DUPLICATE KEY UPDATE 可能不需要或語法錯誤
            # 這裡我們假設 INSERT 總是安全的，如果 ID 已存在，則不做任何事 (如果沒有 UPDATE 子句)
            # 或者，如果確定總是希望插入或更新，那麼 update_fields 不應為空
            # 這裡保持原邏輯，假設 update_fields 通常不為空
             sql = f"""
             INSERT INTO members ({field_names})
             VALUES ({placeholders})
             """
             if not update_fields:
                 logging.warning(f"只有 ID ('{used_id}') 被提供或處理，將執行簡單 INSERT。如果 ID 已存在且無 ON DUPLICATE KEY UPDATE，可能無操作或報錯 (取決於主鍵/唯一約束)。")
             else:
                  # 理論上不應該進入這裡，除非 fields 列表只有 'id'
                  logging.error("產生 SQL 時出現未預期情況：update_fields 為空但 SQL 試圖包含它。")
                  raise ValueError("無法產生有效的 SQL 更新語句")


        # --- 執行 SQL ---
        with connection.cursor() as cursor:
            try:
                logging.debug(f"準備執行 SQL: {sql}")
                # 使用 mogrify 可以在日誌中看到參數化後的 SQL (用於除錯，小心敏感資訊)
                # logging.debug(f"Mogrified SQL: {cursor.mogrify(sql, values)}")
                affected_rows = cursor.execute(sql, values)
                connection.commit()
                logging.info(f"資料庫操作成功。影響行數: {affected_rows}。會員 ID: {used_id}")
            except pymysql.Error as db_err:
                connection.rollback()
                logging.error(f"SQL 執行錯誤: {db_err}")
                # 記錄更詳細的錯誤，包括試圖執行的 SQL 和值 (小心敏感資料)
                try:
                    # mogrify 可能在某些錯誤情況下也失敗
                    mogrified_sql = cursor.mogrify(sql, values)
                    logging.error(f"失敗的 SQL (參數化後): {mogrified_sql}")
                except Exception as mog_err:
                    logging.error(f"無法生成 mogrified SQL: {mog_err}")
                    logging.error(f"失敗的 SQL (原始): {sql}")
                    logging.error(f"失敗的值 (部分可能敏感): {values}")
                # 將資料庫錯誤包裝後重新拋出或返回錯誤訊息
                raise Exception(f"資料庫操作失敗: {db_err}") from db_err
            except Exception as e:
                connection.rollback()
                logging.error(f"執行資料庫命令時發生非預期錯誤: {e}")
                raise Exception(f"處理資料庫操作時發生錯誤: {e}") from e

        # --- 準備成功回傳資料 ---
        # 從 data 字典中獲取最終值 (可能已被處理過，如 list 轉 string)
        return_data = {
            "身高": data.get('height'),
            "體重": data.get('weight'),
            "年齡": data.get('age'),
            "性別": data.get('gender'),
            "就寢時間": data.get('sleep_start'),
            "起床時間": data.get('sleep_end'),
            "病史": data.get('medical_history'),
            "其他病史": data.get('medical_history_other'),
            "睡眠品質": data.get('sleep_quality'),
            "睡眠困擾": data.get('sleep_disturbance'),
            "其他睡眠困擾": data.get('sleep_disturbance_other'),
            "日常狀況": data.get('daily_conditions'),
            "其他日常狀況": data.get('daily_conditions_other'),
            "症狀": data.get('symptom'),
            "心理狀況": data.get('psychological_conditions'),
            "其他心理狀況": data.get('psychological_conditions_other'),
            "生活習慣": data.get('lifestyle'),
            "運動狀況": data.get('sports_status'),
            "運動頻率": data.get('sports_freq'), # 這裡會是處理過的字串或 None 或原始值
            "睡前活動": data.get('before_bed'),
            "其他睡前活動": data.get('before_bed_other')
        }

        return {
            "result": "success",
            "message": "會員資料已成功新增或更新。",
            "member_id": used_id, # 返回實際使用的 ID
            "data": return_data
        }

    except Exception as e:
        logging.exception(f"在 add_member 函數中發生錯誤 (會員 ID 可能為: {used_id})") # 記錄完整 traceback
        # 發生錯誤時返回錯誤信息
        # 不建議在生產環境的回應中包含原始輸入數據 `data`，可能洩露敏感資訊
        error_response = {
            "result": "error",
            "error_message": f"處理請求時發生錯誤: {str(e)}",
            "member_id": used_id # 即使錯誤，也嘗試返回 ID (如果已生成)
        }
        return error_response

    finally:
        # --- 確保關閉連線 ---
        if connection and connection.open:
            try:
                connection.close()
                logging.info("資料庫連線已關閉")
            except pymysql.Error as e:
                logging.error(f"關閉資料庫連線時發生錯誤: {e}")