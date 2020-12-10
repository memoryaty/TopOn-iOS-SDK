//
//  toponApi.swift
//  AnyThinkSDK
//
//  Created by qfdev on 2020/12/9.
//  Copyright © 2020 AnyThink. All rights reserved.
//

import Foundation

//1.请求应用配置，请求参数，接口v1/open/app，地址api.anythinktech.com
{
    "p":""
    "sign":""
    "p2":""
    "api_ver":""
}
//参数内容
"p" = {//json转base64编码
    nonSubjectFields// start这部分参数后续请求也会发
    "app_id"//sdk appID
    "platform"//参数值为2，应该是手机平台
    "package_name"//包名
    "app_vn"//应用版本号
    "app_vc"//应用版本号
    "sdk_ver"//sdk版本号
    "nw_ver"//networkVersions，新版本废弃参数
    "orient"//屏幕方向
    "system"//值为1
    "gdpr_cs"//参数为1或0或2
    //end
    protectedFields// start这部分参数后续请求也会发
    "os_vn"//系统版本
    "os_vc"//系统版本
    "network_type"//网络类型notReach=-1,reachableWifi=-2,reachWan=13
    "mnc"//网络运营商code
    "mcc"//网络运营商国家code
    "language"//语言
    "brand"//为“apple”或空字符串，作用不明
    "model"//架构，X86_64
    "timezone"//时区
    "screen"//屏幕尺寸
    "ua"//userAgent,
    "upid"//uuid转md5
    "sy_id"
    "bk_id"
    //end
    "ps_id"//进程ID，可以为空
    "channel"
    "sub_channel"
    "first_init_time"//首次启动时间戳
    "days_from_first_init"//距首次启动的天数
}

"p2" = {//json转base64编码
    "idfa"
    "idfv"
}

"sign" = {//base64编码
    "p":value
    "p2":value
    "api_ver": "1.0"
}

//1.请求应用配置下发"data"
{
    "abtest_id" = "4b9ca0f9bd36a9b48dffb443292700eb";
    adx =     {
        "bid_addr" = "https://adx.anythinktech.com/bid";
        "bid_sw" = 1;
        "ol_req_addr" = "https://adx.anythinktech.com/openapi/req";
        "req_addr" = "https://adx.anythinktech.com/request";
        "req_sw" = 1;
        "req_tcp_addr" = "";
        "req_tcp_port" = "";
        "tk_addr" = "https://adxtk.anythinktech.com/v1";
        "tk_sw" = 1;
        "tk_tcp_addr" = "";
        "tk_tcp_port" = "";
    };
    "c_a" = 51200;
    "crash_list" =     (
        "com.anythink"
    );
    "crash_sw" = 1;
    "data_level" =     {
        a = 1;
        i = 0;
        m = 0;
    };
    "gdpr_a" =  (
        "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IS", "IE", "IT", "LV", "LI", "LT", "LU", "MT", "NL", "NO", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "GB", "UK"
    );
    "gdpr_ia" = 0;
    "gdpr_nu" = "https://img.anythinktech.com/gdpr/PrivacyPolicySetting.html";
    "gdpr_sdcs" = 0;
    "gdpr_so" = 0;
    "la_sw" = 2;
    logger =     {
        "da_address" = "https://da.anythinktech.com/v1/open/da";
        "da_interval" = 60000;
        "da_max_amount" = 8;
        "da_not_keys" = "[]";
        "da_not_keys_ft" = "{}";
        "da_rt_keys" = "[]";
        "da_rt_keys_ft" = "{}";
        "tcp_domain" = "tkda.anythinktech.com";
        "tcp_port" = 9377;
        "tcp_rate" = "";
        "tcp_tk_da_type" = 0;
        "tk_address" = "https://tk.anythinktech.com/v1/open/tk";//_trackerAddress
        "tk_interval" = 10000;
        "tk_max_amount" = 8;
        "tk_no_t" = "[]";
        "tk_no_t_ft" = "{}";
        "tk_timer_sw" = 1;
        "up_da_li" = "kCrZ/yFHmE+HuEMs9eBHuaoPKqsqlENHuEMs9eBHuaoPKqsquEMs2CDS2yMimxDG9aUqEN==";
    };
    "n_l" = "{}";//_notifications
    "n_psid_tm" = 30000;
    "nw_eu_def" = 1;
    "pl_n" = 5000;
    "psid_hl" = 60000;
    "req_ver" = "1.0";
    scet = 3600000;
    "t_c" = "{\"k\":\"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/\",\"v\":\"dMWnhbeyKr0JIvLNOx3BFkEuml92Y5fjSqGT7R8pZVciPHAstC4UXa6QDw1goz+/\"}";
    upid = "9f89c84a559f573636a47ff8daed0d33";//uuid转md5
}

//2.请求启屏广告,接口v1/open/placement地址api.anythinktech.com
{
    "p"
    "p2"
    "api_ver":"1.0"
    "sign"
}

p = {
    protectedFields//上面的字段
    nonSubjectFields
    "pl_id"//placementID
    "ps_id"//进程ID
    "channel"
    "sub_channel"
    "first_init_time"
    "days_from_first_init"
    "ecpoffer"//不包含的设备ID
    "exclude_myofferid"
    "abtest_id"
}

//2.请求启屏，下发"data"
{
    "ad_delivery_sw" = 1;//广告投放开关，0广告不显示
    "addr_bid" = "https://adx.anythinktech.com/bid";
    "adx_list" =     (
    );
    "adx_st" =     {
        "ak_cfm" = 1;
        clua = 1;
        cm = 2;
        "dp_cm" = 1;
        "e_c_a" = 1;
        "f_t" = 4;
        ipua = 1;
        "l_o_num" = 5;
        "ld_t" = 1;
        "m_t" = 600000;
        "s_b_t" = 0;
        "s_t" = 1;
        "v_c" = 2;
    };
    "asid" = 2be14d32596e744cbe5d5aede655c769;
    "auto_refresh" = 0;
    "auto_refresh_time" = 20000;
    "cached_offers_num" = 1;
    callback =     {
        cc = CN;
        currency = USD;
        reward =         {
            "rw_n" = "reward_item";
            "rw_num" = 1;
        };
    };
    "fbhb_bid_wtime" = 10000;
    "format" = 4;
    "gro_id" = 0;//流量分组？
    "hb_bid_timeout" = 10000;
    "hb_list" =     (
    );
    "hb_start_time" = 2000;
    "inh_list" =     (
    );
    "l_s_t" = 300000;
    "load_cap" = "-1";
    "load_cap_time" = 900000;
    "load_fail_wtime" = 10000;
    "m_o" =     (
    );
    "m_o_ks" =     {
    };
    "m_o_s" =     {//_myOfferSetting
        "ak_cfm" = 0;
        "cl_btn" = 0;
        "ctdown_time" = 5000;
        "e_c_a" = 0;
        "f_t" = 4;
        "m_t" = 20000;
        "o_c_t" = 604800000;
        "orient" = 1;
        "s_b_t" = 0;
        "s_c_t" = "-1";
        "size" = 320x50;
        "sk_able" = 0;
        "skit_time" = 1;
        "v_c" = 0;
        "v_m" = 1;
    };
    "ol_list" =     (
    );
    "p_m_o" = 1;//_preloadMyOffer
    "ps_ct" = 1800000;//缓存有效时间
    "ps_ct_out" = 0;
    "ps_id" = cbd5fb81ed53bff499e1bcb51a6d8803;
    "ps_id_timeout" = 1800000;
    "pucs" = 1;//是否缓存
    "ra" = 0;//_autoloadingEnabled
    "refresh" = 0;
    "req_ug_num" = 1;//当前最高请求次数
    "s2shb_list" =     (
    );
    "s_id" = "";
    "s_t" = 900000;//_offerLoadingTimeout /1000
    "session_id" = "910789b8abdc08279c91cbfea4913136";
    "show_type" = 0;
    "t_g_id" = 18142;
    "tp" = "-1";
    "u_n_f_sw" = 0;//_usesDefaultMyOffer
    "ug_list" =     (//广告信息
                {
            "adapter_class" = "ATGDTSplashAdapter";//第三方SDK类名,ATAdmobSplashAdapter,ATMintegralSplashAdapter,ATSigmobSplashAdapter,ATTTSplashAdapter,ATBaiduSplashAdapter,ATGDTSplashAdapter
            "bid_fail_interval" = 600000;
            "c_sw" = 0;//_postsNotificationOnClick
            "caps_d" = "-1";
            "caps_h" = "-1";
            "content" = "{\"unit_id\":\"4081423639975104\",\"app_id\":\"1110921192\"}";//第三方广告应用ID和广告位ID，字段可能不一样
            "ecpm" = 10;//排序价格
            "ecpm_level" = 1;
            "hb_t_c_t" = 1800000;
            "hb_timeout" = 2000;
            "l_s_t" = 900000;
            "n_d_t" = "-1";
            "nw_cache_time" = 1800000;
            "nw_firm_id" = 8;//_networkFirmID
            "nw_firm_name" = "Tencent Ads";
            "nw_req_num" = 1;//_networkRequestNum
            "nw_timeout" = 5000;
            "nx_req_time" = 0;
            "pacing" = "-1";
            "precision" = "publisher_defined";
            "s_sw" = 0;//_postsNotificationOnShow
            "t_c_u" = "https://tk.anythinktech.com/v1/open/tk";//上报数据的地址
            "t_c_u_max_t" = 5000;
            "t_c_u_min_t" = 2000;
            "ug_id" = 13797030;//_unitGroupID
            "unit_id" = 116915;
        },
                {
            "adapter_class" = ATTTSplashAdapter;
            "bid_fail_interval" = 600000;
            "c_sw" = 0;
            "caps_d" = "-1";
            "caps_h" = "-1";
            content = "{\"personalized_template\":\"0\",\"slot_id\":\"887371539\",\"app_id\":\"5100601\"}";
            ecpm = 9;
            "ecpm_level" = 2;
            "hb_t_c_t" = 1800000;
            "hb_timeout" = 2000;
            "l_s_t" = 900000;
            "n_d_t" = "-1";
            "nw_cache_time" = 1800000;
            "nw_firm_id" = 15;
            "nw_firm_name" = Pangle;
            "nw_req_num" = 1;
            "nw_timeout" = 5000;
            "nx_req_time" = 0;
            pacing = "-1";
            precision = "publisher_defined";
            "s_sw" = 0;
            "t_c_u" = "https://tk.anythinktech.com/v1/open/tk";
            "t_c_u_max_t" = 5000;
            "t_c_u_min_t" = 2000;
            "ug_id" = 13693818;
            "unit_id" = 60893;
        }
    );
    "unit_caps_d" = "-1";
    "unit_caps_h" = "-1";
    "unit_pacing" = "-1";//广告pacing，如果返回>=0，则广告不展示，log为广告展示过于频繁，两次AD间隔小于广告中的设置
    "wifi_auto_sw" = 1;//wifi下视频自动播放
}

