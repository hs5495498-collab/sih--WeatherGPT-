import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/weather_data.dart';
import '../theme/app_theme.dart';
import 'animated_counter.dart';
import 'animated_weather_icon.dart';

class WeatherHeroCard extends StatelessWidget {
  const WeatherHeroCard({super.key, required this.data, this.compact = false});

  final WeatherData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.gradientFor(data.condition);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.location,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedCounter(
                      value: data.tempC,
                      suffix: '°C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 34 : 46,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 4),
                    Text(
                      data.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedWeatherIcon(
                condition: data.condition,
                size: compact ? 44 : 60,
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                _statChip(Icons.water_outlined, '${data.humidityPct}% humidity'),
                const SizedBox(width: 10),
                _statChip(Icons.air_rounded, '${data.windKmh.round()} km/h'),
              ],
            ),
          ],
          if (data.forecast.isNotEmpty && !compact) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.forecast.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final f = data.forecast[i];
                  return Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekday(f.date),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        AnimatedWeatherIcon(condition: f.condition, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          '${f.tempMaxC.round()}°',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (i * 80).ms, duration: 350.ms)
                      .slideX(begin: 0.15, end: 0);
                },
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  String _weekday(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }
}
