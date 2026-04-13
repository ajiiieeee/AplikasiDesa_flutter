import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/groq_service.dart';
import '../services/surat_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];

  bool isLoading = false;

  String? userPhoto;

  @override
  void initState() {
    super.initState();
    getUserPhoto();

    /// Welcome message
    messages.add({
      "role": "bot",
      "message": "Halo 👋\nSaya Chatbot Desa.\n\nSaya bisa membantu:\n• Persyaratan surat\n• Cara pengajuan surat\n• Informasi administrasi desa"
    });
  }

  Future<void> getUserPhoto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userPhoto = prefs.getString('foto');
    });
  }

  void scrollToBottom(){
    Future.delayed(const Duration(milliseconds: 300),(){
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds:300),
        curve: Curves.easeOut
      );
    });
  }

  Future<void> kirimPesan() async {

    String pesanUser = _controller.text;

    if (pesanUser.isEmpty) return;

    setState(() {
      messages.add({
        "role": "user",
        "message": pesanUser
      });
      isLoading = true;
    });

    _controller.clear();

    scrollToBottom();

    String? jawabanLokal = SuratService.cekPertanyaan(pesanUser);

    String balasan;

    if (jawabanLokal != null) {

      balasan = jawabanLokal;

    } else {

      balasan = await GroqService.sendMessage(pesanUser);

    }

    setState(() {

      messages.add({
        "role": "bot",
        "message": balasan
      });

      isLoading = false;

    });

    scrollToBottom();

  }

  Widget buildMessage(Map<String,String> msg){

    bool isUser = msg["role"] == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical:6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          /// AVATAR BOT
          if (!isUser)
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage("assets/images/bot.png"),
            ),

          if (!isUser) const SizedBox(width: 8),

          /// BUBBLE CHAT
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                msg["message"] ?? "",
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                  fontSize: 14
                ),
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 8),

          /// AVATAR USER LOGIN
          if (isUser)
            CircleAvatar(
              radius: 18,
              backgroundImage: userPhoto != null
                  ? NetworkImage("http://192.168.1.10:8000/storage/$userPhoto")
                  : const AssetImage("assets/images/user.png") as ImageProvider,
            ),

        ],
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Chatbot Desa"),
      ),

      body: Column(

        children: [

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context,index){

                return buildMessage(messages[index]);

              },
            ),
          ),

          /// TYPING INDICATOR
          if(isLoading)
          const Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage("assets/images/bot.png"),
                ),
                SizedBox(width: 10),
                Text("Chatbot sedang mengetik...")
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal:10,vertical:5),
            child: Row(

              children: [

                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Tanyakan sesuatu...",
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: kirimPesan,
                )

              ],
            ),
          )

        ],
      ),
    );
  }
}