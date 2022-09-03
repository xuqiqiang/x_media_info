#include "x_media_info_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <thread>

extern "C" {
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavutil/avutil.h"
#include "libavutil/error.h"
#pragma comment(lib, "avformat.lib")
#pragma comment(lib, "avcodec.lib")
#pragma comment(lib, "avutil.lib")
}

#if defined(__ANDROID__)
#include <android/log.h>
#define LOG(...) __android_log_print(ANDROID_LOG_ERROR,"XPlayer_jni",__VA_ARGS__)
#else
#define LOG(...) printf(__VA_ARGS__)
#endif

namespace x_media_info {

static std::unique_ptr<flutter::MethodChannel<>> m_channel;
static volatile bool has_register_ffmpeg = false;


bool decode(AVPacket* pkt, AVFrame* frm, AVCodecContext* codecContext)
{
    int ret = AVERROR(EAGAIN);
    for (;;)
    {
        do {
            printf("avcodec_receive_frame1 %d\n", frm->width);
            ret = avcodec_receive_frame(codecContext, frm);  //解码出真正的frame
            if (ret == AVERROR_EOF)
            {
                avcodec_flush_buffers(codecContext);
                return false;
            }
            else if (ret >= 0)
            {
                return true;
            }

        } while (ret != AVERROR(EAGAIN));
        printf("avcodec_receive_frame2 %d\n", frm->width);
        if (avcodec_send_packet(codecContext, pkt) == AVERROR(EAGAIN)) //送packet数据
        {
            return false;
        }
    }
    return false;
}

DWORD WINAPI TCheckDeviceInfo(TParam* param) {
    
    int width = 0;
    int height = 0;
    int64_t duration = 0;
    float video_frame_rate = 0;
    int video_codec_id = 0;
    int audio_codec_id = 0;

    if (!has_register_ffmpeg) {
        has_register_ffmpeg = true;
        av_register_all();
    }
    avformat_network_init();
    AVFormatContext* ic = avformat_alloc_context();

    AVDictionary* format_opts = NULL;
    /*if (ctx->password) {
        // 指定解密key
        av_dict_set(&format_opts, "decryption_key", ctx->password, 0);
    }*/
    //av_dict_set(&format_opts, "timeout", "20000", 0);
    //av_dict_set(&format_opts, "stimeout", "20000000", 0);
    int ret = avformat_open_input(&ic, param->uri, NULL, &format_opts);
    if (ret < 0) {
        LOG("avformat_open_input error %d %s\n", ret, av_err2str(ret));
    }
    else {
        LOG("avformat_open_input 1\n");
        av_dump_format(ic, 0, param->uri, 0);

        duration = ic->duration;
        if (duration < 0) duration = 0;

        //寻找视频流
        int video_stream_idx = -1;
        for (int i = 0; i < ic->nb_streams; i++) {
            if (ic->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
                //video_stream_idx = i;
                LOG("AVMEDIA_TYPE_VIDEO %d\n", i);
                AVStream* vs = ic->streams[i];
                if (vs->avg_frame_rate.den == 0) video_frame_rate = 0;
                else video_frame_rate = av_q2d(vs->avg_frame_rate);
                video_codec_id = vs->codec->codec_id;
                width = vs->codec->width;
                height = vs->codec->height;

                printf("codec %d %d\n", width, height);
                
                if (width == 0 && height == 0 && param->detail) {

                    AVCodec* pCodec = avcodec_find_decoder(vs->codec->codec_id);
                    ret = avcodec_open2(vs->codec, pCodec, nullptr);
                    if (ret < 0) {
                        printf("cannot open software codec %s\n", pCodec->name);
                        //return -1; // Could not open codec
                    }
                    else {
                        printf("pCodec %s\n", pCodec->name);

                        //解封装
                        AVPacket* packet = av_packet_alloc();
                        packet->stream_index = -1;
                        while (packet->stream_index != i){
                            ret = av_read_frame(ic, packet);
                            if (ret == AVERROR_EOF) {
                                break;
                            }
                        }

                        if (packet->stream_index == i) {
                            AVFrame* out_avframe = av_frame_alloc();
                            if (out_avframe) {
                                ret = decode(packet, out_avframe, vs->codec);
                                printf("decode %d\n", ret);
                                if (ret) {
                                    printf("out_avframe %d %d\n", out_avframe->width, out_avframe->height);
                                    width = out_avframe->width;
                                    height = out_avframe->height;
                                }

                                //删除frame
                                av_frame_free(&out_avframe);
                            }

                        }

                        //删除packet
                        av_packet_free(&packet);

                        //关闭解码器上下文
                        avcodec_close(vs->codec);
                    }
                }
                break;
            }
        }

        //寻找音频流
        int audio_stream_idx = -1;
        for (int i = 0; i < ic->nb_streams; i++) {
            if (ic->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
                LOG("AVMEDIA_TYPE_AUDIO %d\n", i);
                AVStream* vs = ic->streams[i];
                audio_codec_id = vs->codec->codec_id;
                break;
            }
        }
    }

    avformat_network_deinit();
    if (format_opts) av_dict_free(&format_opts);
    avformat_close_input(&ic);

    std::string info = "{\"id\":\"" + std::string(param->id) + "\""
        + ",\"width\":" + std::to_string(width)
        + ",\"height\":" + std::to_string(height)
        + ",\"videoFrameRate\":" + std::to_string(video_frame_rate)
        + ",\"videoCodecId\":" + std::to_string(video_codec_id)
        + ",\"audioCodecId\":" + std::to_string(audio_codec_id)
        + ",\"duration\":" + std::to_string(duration / 1000)
        + "}";

    if (m_channel != NULL) {
        m_channel->InvokeMethod("onMediaInfo",
            std::make_unique<flutter::EncodableValue>(info));
    }
    free(param->uri);
    free(param->id);
    delete param;
    return 0;
}

// static
void XMediaInfoPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "x_media_info",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<XMediaInfoPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  m_channel = std::move(channel);
  registrar->AddPlugin(std::move(plugin));
}

XMediaInfoPlugin::XMediaInfoPlugin() {}

XMediaInfoPlugin::~XMediaInfoPlugin() {
    m_channel = NULL;
}

char* CopyString(std::string str) {
    char* cs = (char*)malloc(str.length() + 1);
    if (cs != NULL) strcpy(cs, str.c_str());
    return cs;
}

static char* VecToLPSTR(std::vector<unsigned char> vec) {
    char* cs = (char*)malloc((vec.size() + 1) * sizeof(char));
    if (cs == NULL) return NULL;
    for (int i = 0; i < vec.size(); i++) {
        cs[i] = vec[i];
    }
    cs[vec.size()] = '\0';
    return cs;
}

void XMediaInfoPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_call.method_name().compare("getMediaInfo") == 0) {
    const flutter::EncodableMap& args =
      std::get<flutter::EncodableMap>(*method_call.arguments());
    // GBK格式的字符集
    std::vector<unsigned char> vec_uri = std::get<std::vector<unsigned char>>(
      args.at(flutter::EncodableValue("uri")));
    std::string id = std::get<std::string>(args.at(flutter::EncodableValue("id")));
    char* uri = VecToLPSTR(vec_uri);
    bool detail = std::get<bool>(
        args.at(flutter::EncodableValue("detail")));

    TParam* param = new TParam;
    param->uri = VecToLPSTR(vec_uri);
    param->id = CopyString(id);
    param->detail = detail;
    std::thread th(TCheckDeviceInfo, param);
    th.detach();

    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace x_media_info
