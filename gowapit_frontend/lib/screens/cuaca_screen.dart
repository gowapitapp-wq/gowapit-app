import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CuacaScreen extends StatefulWidget {
  const CuacaScreen({super.key});

  @override
  State<CuacaScreen> createState() => _CuacaScreenState();
}

class _CuacaScreenState extends State<CuacaScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _currentWeather = {};
  List<dynamic> _dailyWeather = [];

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=-7.2558&longitude=110.0183&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,rain,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m&hourly=temperature_2m,precipitation,rain,apparent_temperature,precipitation_probability,weather_code,wind_speed_80m,wind_direction_10m,wind_gusts_10m,temperature_80m,uv_index_clear_sky,uv_index,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_clear_sky_max&timezone=auto'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentWeather = data['current'];
            final dailyData = data['daily'];
            _dailyWeather = List.generate(7, (index) {
              return {
                'time': dailyData['time'][index],
                'weather_code': dailyData['weather_code'][index],
                'temp_max': dailyData['temperature_2m_max'][index],
                'temp_min': dailyData['temperature_2m_min'][index],
                'precip_prob': dailyData['precipitation_probability_max'][index],
                'sunrise': dailyData['sunrise'][index],
                'sunset': dailyData['sunset'][index],
                'uv_index': dailyData['uv_index_clear_sky_max'][index],
              };
            });
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat cuaca: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- KAMUS CUACA (KINI MENGGUNAKAN PATH GAMBAR 3D) ---
  Map<String, dynamic> _getWeatherInfo(int code) {
    if (code == 0) return {'desc': 'Cerah', 'image': 'assets/images/3d_sun.png', 'color': Colors.orange};
    if (code == 1 || code == 2 || code == 3) return {'desc': 'Berawan', 'image': 'assets/images/3d_cloud.png', 'color': Colors.grey};
    if (code == 45 || code == 48) return {'desc': 'Berkabut', 'image': 'assets/images/3d_fog.png', 'color': Colors.blueGrey};
    if (code == 51 || code == 53 || code == 55) return {'desc': 'Gerimis', 'image': 'assets/images/3d_drizzle.png', 'color': Colors.lightBlue};
    if (code == 61 || code == 63 || code == 65) return {'desc': 'Hujan', 'image': 'assets/images/3d_rain.png', 'color': Colors.blue};
    if (code == 80 || code == 81 || code == 82) return {'desc': 'Hujan Deras', 'image': 'assets/images/3d_heavy_rain.png', 'color': Colors.indigo};
    if (code == 95 || code == 96 || code == 99) return {'desc': 'Badai Petir', 'image': 'assets/images/3d_thunderstorm.png', 'color': Colors.deepPurple};
    return {'desc': 'Cerah Berawan', 'image': 'assets/images/3d_cloud.png', 'color': Colors.blue}; 
  }

  String _formatHari(String dateString) {
    DateTime date = DateTime.parse(dateString);
    if (date.day == DateTime.now().day) return "Hari Ini";
    if (date.day == DateTime.now().add(const Duration(days: 1)).day) return "Besok";
    List<String> hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return hari[date.weekday - 1];
  }

  String _formatJam(String isoDate) {
    DateTime date = DateTime.parse(isoDate);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFD0EFB1);
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    final List<BoxShadow> ambientShadow = isDarkMode ? [] : [
      BoxShadow(color: const Color(0xFF9DC3C2).withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8))
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text("Cuaca Wapit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Montserrat')),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
              child: Column(
                children: [
                  // ==========================================
                  // 1. KARTU CUACA UTAMA 
                  // ==========================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: ambientShadow,
                    ),
                    child: Column(
                      children: [
                        // --- GAMBAR 3D UTAMA ---
                        Image.asset(
                          _getWeatherInfo(_currentWeather['weather_code'])['image'],
                          width: 150, 
                          height: 150,
                          fit: BoxFit.contain,
                          // Fallback jika gambar 3D belum dimasukkan ke folder
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.cloud_queue, 
                            size: 100, 
                            color: _getWeatherInfo(_currentWeather['weather_code'])['color']
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_currentWeather['temperature_2m'].round()}",
                              style: TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Montserrat', height: 1),
                            ),
                            Text("°", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
                          ],
                        ),
                        
                        Text(
                          _getWeatherInfo(_currentWeather['weather_code'])['desc'],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: subTextColor, fontFamily: 'Montserrat'),
                        ),
                        const SizedBox(height: 30),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoItem(Icons.air, "${_currentWeather['wind_speed_10m']} km/h", "Angin", subTextColor, textColor),
                            _buildInfoItem(Icons.water_drop_outlined, "${_currentWeather['relative_humidity_2m']}%", "Lembap", subTextColor, textColor),
                            _buildInfoItem(Icons.umbrella_outlined, "${_dailyWeather[0]['precip_prob']}%", "Hujan", subTextColor, textColor),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // 2. KARTU DETAIL EKSTRA
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: ambientShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Detail Hari Ini", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildExtraInfo(Icons.thermostat, "${_currentWeather['apparent_temperature']}°", "Terasa", primaryColor, textColor, subTextColor),
                            _buildExtraInfo(Icons.brightness_high, "${_dailyWeather[0]['uv_index']}", "UV Index", Colors.orange, textColor, subTextColor),
                            _buildExtraInfo(Icons.wb_twilight, _formatJam(_dailyWeather[0]['sunrise']), "Terbit", Colors.amber, textColor, subTextColor),
                            _buildExtraInfo(Icons.nights_stay, _formatJam(_dailyWeather[0]['sunset']), "Terbenam", Colors.deepPurple.shade300, textColor, subTextColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // 3. PREDIKSI 7 HARI KEDEPAN
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: ambientShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 10),
                          child: Text("7 Hari Kedepan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                        ),
                        ...List.generate(_dailyWeather.length, (index) {
                          final hariIni = _dailyWeather[index];
                          final info = _getWeatherInfo(hariIni['weather_code']);
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    _formatHari(hariIni['time']),
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: index == 0 ? primaryColor : subTextColor, fontFamily: 'Inter'),
                                  ),
                                ),
                                
                                Expanded(
                                  child: Row(
                                    children: [
                                      // --- GAMBAR 3D KECIL DI LIST ---
                                      Image.asset(
                                        info['image'],
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.contain,
                                        // Fallback jika gambar 3D belum dimasukkan ke folder
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          Icons.cloud_queue, 
                                          color: info['color'], 
                                          size: 26
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        info['desc'],
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor, fontFamily: 'Inter'),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                Row(
                                  children: [
                                    Text(
                                      "+${hariIni['temp_max'].round()}°",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "+${hariIni['temp_min'].round()}°",
                                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: subTextColor),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget Pembantu untuk Kartu Utama (Tetap 2D Icon agar clean)
  Widget _buildInfoItem(IconData icon, String value, String label, Color subTextColor, Color textColor) {
    return Column(
      children: [
        Icon(icon, color: subTextColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor, fontFamily: 'Inter')),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter')),
      ],
    );
  }

  // Widget Pembantu untuk Kotak Detail Ekstra (Tetap 2D Icon agar clean)
  Widget _buildExtraInfo(IconData icon, String value, String label, Color iconColor, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor, fontFamily: 'Inter')),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter')),
      ],
    );
  }
}