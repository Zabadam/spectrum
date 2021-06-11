/// Provides three types of extended `Gradient`s aptly named `Steps`,
/// as they do not gradate but instead hard-transition.
/// - [LinearSteps], [RadialSteps], [SweepSteps]
library spectrum;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals, objectRuntimeType;

import '../common.dart';

extension _DuplicateColors on List<Color> {
  /// Takes a `List<Color>` and returns a list with duplicated entries.
  List<Color> operator ~() =>
      fold([], (List<Color> list, Color entry) => list..addAll([entry, entry]));
}

extension _DuplicateStops on List<double> {
  /// Takes a `List<double>` and returns a list with duplicated entries where
  /// every duplicated entry may optionally have an [additive] added to it.
  List<double> operator ^(double additive) => fold(
      [],
      (List<double> list, double entry) =>
          list..addAll([entry, entry + additive]));
}

/// These `Steps` work a little bit differently than standard `Gradient`s.
///
/// The [Gradient.colors] & [Gradient.stops] fields are overridden
/// with getters that duplicate these `List`s.
///
/// But while [colors] is a duplicated [Gradient.colors], these [stops], if
/// provided manually instead of using interpretation, are expected to follow
/// a simple, but important format:
/// - This constructor's `stops` *should* start with a `0.0`, as after
///   list duplication, the second entry in the list will be eliminated.
/// - This constructor's `stops` *should not* end with a `1.0`, as that will
///   be added automatically.
abstract class Steps extends Gradient {
  /// These `Steps` work a little bit differently than standard `Gradient`s.
  ///
  /// The [Gradient.colors] & [Gradient.stops] fields are overridden
  /// with getters that duplicate these `List`s.
  ///
  /// But while [colors] is a duplicated [Gradient.colors], these [stops], if
  /// provided manually instead of using interpretation, are expected to follow
  /// a simple, but important format:
  /// - This constructor's `stops` *should* start with a `0.0`, as after
  ///   list duplication, the second entry in the list will be eliminated.
  /// - This constructor's `stops` *should not* end with a `1.0`, as that will
  ///   be added automatically.
  const Steps({
    this.softness = 0.0,
    required List<Color> colors,
    List<double>? stops,
    GradientTransform? transform,
  }) :
        // stops = stops,
        super(
          colors: colors,
          stops: stops,
          transform: transform,
        );

  /// An incredibly small `double` to provide as an `additive` for each second
  /// entry when duplicating [stops] for this `Steps`.
  ///
  /// A larger  `softness` has the effect of reducing the hard edge in-between
  /// each color in this `Steps`, making it more like its original [Gradient]
  /// counterpart.
  ///
  /// Imagine [stops] is `[0.0, 0.3, 0.8]`*. Providing a `softness` of `0.001`,
  /// the effective, resolved [stops] for this `Gradient` is now:
  ///
  /// `[0.0, 0.3, 0.3001, 0.8, 0.8001, 1.0]`.
  ///
  /// ## \* *Note*:
  /// These `Steps` work a little bit differently than standard `Gradient`s.
  ///
  /// The [Gradient.colors] & [Gradient.stops] fields are overridden
  /// with getters that duplicate these `List`s.
  ///
  /// But while [colors] is a duplicated [Gradient.colors], these [stops], if
  /// provided manually instead of using interpretation, are expected to follow
  /// a simple, but important format:
  /// - This constructor's `stops` *should* start with a `0.0`, as after
  ///   list duplication, the second entry in the list will be eliminated.
  /// - This constructor's `stops` *should not* end with a `1.0`, as that will
  ///   be added automatically.
  final double softness;

  // final List<double>? _stops;
  // @override
  // List<double>? get stops =>
  //     List<double>.from(interpretStops(stops, colors.length + 1))
  //       ..removeLast();

  List<Color> get steppedColors => ~colors;

  List<double> get steppedStops {
    final _stops =
        (List<double>.from(interpretStops(stops, colors.length + 1)));

    /// If local `stops` is not null, above [interpretStops] will return
    /// that exact value. In that case, we do not want to build a stop list
    /// with an extra value and cut it off... just use the provided `stops`.
    if (stops == null) _stops.removeLast();
    return _stops ^ softness
      // ..removeAt(0)
      // ..add(1.0)
      ..remove(0)
      ..add(1.0);
  }
}

class LinearSteps extends Steps {
  const LinearSteps({
    double softness = 0.001,
    required List<Color> colors,
    List<double>? stops,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    this.tileMode = TileMode.clamp,
    GradientTransform? transform,
  }) : super(
          softness: softness,
          colors: colors,
          stops: stops,
          transform: transform,
        );

  final AlignmentGeometry begin, end;
  final TileMode tileMode;

  @override
  ui.Shader createShader(ui.Rect rect, {ui.TextDirection? textDirection}) {
    return LinearGradient(
      colors: steppedColors,
      stops: steppedStops,
      transform: transform,
      begin: begin,
      end: end,
      tileMode: tileMode,
    ).createShader(rect, textDirection: textDirection);
  }

  /// Returns a new [LinearSteps] with its colors scaled by the given factor.
  /// Since the alpha channel is what receives the scale factor,
  /// `0.0` or less results in a gradient that is fully transparent.
  @override
  LinearSteps scale(double factor) => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, factor)!)
            .toList(),
      );

  @override
  Gradient? lerpFrom(Gradient? a, double t) => (a == null || (a is LinearSteps))
      ? LinearSteps.lerp(a as LinearSteps?, this, t)
      : super.lerpFrom(a, t);

  @override
  Gradient? lerpTo(Gradient? b, double t) => (b == null || (b is LinearSteps))
      ? LinearSteps.lerp(this, b as LinearSteps?, t)
      : super.lerpTo(b, t);

  /// Linearly interpolate between two [LinearSteps].
  ///
  /// If either `LinearSteps` is `null`, this function linearly interpolates
  /// from a `LinearSteps` that matches the other in [begin], [end], [stops] and
  /// [tileMode] and with the same [colors] but transparent (using [scale]).
  ///
  /// If neither `LinearSteps` is `null`,
  /// they must have the same number of [colors].
  ///
  /// The `t` argument represents a position on the timeline, with `0.0` meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), `1.0` meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond `0.0`
  /// and `1.0`, so negative values and values greater than `1.0` are valid
  /// (and can easily be generated by curves such as `Curves.elasticInOut`).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>],
  /// such as an `AnimationController`.
  static LinearSteps? lerp(LinearSteps? a, LinearSteps? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!.scale(t);
    if (b == null) return a.scale(1.0 - t);
    final interpolated = PrimitiveGradient.interpolateFrom(a, b, t);
    return LinearSteps(
      softness: ui.lerpDouble(a.softness, b.softness, t) ?? 0,
      colors: interpolated.colors,
      stops: interpolated.stops,
      // TODO: Interpolate Matrix4 / GradientTransform
      transform: t > 0.5 ? a.transform : b.transform,
      // TODO: interpolate tile mode
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
      begin: AlignmentGeometry.lerp(a.begin, b.begin, t)!,
      end: AlignmentGeometry.lerp(a.end, b.end, t)!,
    );
  }

  /// 📋 Returns a new copy of this `LinearSteps` with any provided
  /// optional parameters overriding those of `this`.
  LinearSteps copyWith({
    double? softness,
    List<Color>? colors,
    List<double>? stops,
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
    TileMode? tileMode,
    GradientTransform? transform,
  }) =>
      LinearSteps(
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        begin: begin ?? this.begin,
        end: end ?? this.end,
        tileMode: tileMode ?? this.tileMode,
        transform: transform ?? this.transform,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is LinearSteps &&
        other.softness == softness &&
        listEquals<Color>(other.colors, colors) &&
        listEquals<double>(other.stops, stops) &&
        other.tileMode == tileMode &&
        other.begin == begin &&
        other.end == end;
  }

  @override
  int get hashCode => hashValues(
      softness, hashList(colors), hashList(stops), tileMode, begin, end);

  @override
  String toString() => '${objectRuntimeType(this, 'LinearSteps')} ($softness, '
      'resolved colors: $steppedColors, resolved stops: $steppedStops, '
      '$tileMode, $begin, $end)';
}

class RadialSteps extends Steps {
  const RadialSteps({
    double softness = 0.0025,
    required List<Color> colors,
    List<double>? stops,
    this.center = Alignment.center,
    this.radius = 0.5,
    this.focal,
    this.focalRadius = 0.0,
    this.tileMode = TileMode.clamp,
    GradientTransform? transform,
  }) : super(
          softness: softness,
          colors: colors,
          stops: stops,
          transform: transform,
        );

  final AlignmentGeometry center;
  final double radius;
  final AlignmentGeometry? focal;
  final double focalRadius;
  final TileMode tileMode;

  @override
  ui.Shader createShader(ui.Rect rect, {ui.TextDirection? textDirection}) =>
      RadialGradient(
        colors: steppedColors,
        stops: steppedStops,
        transform: transform,
        center: center,
        radius: radius,
        focal: focal,
        focalRadius: focalRadius,
        tileMode: tileMode,
      ).createShader(rect, textDirection: textDirection);

  /// Returns a new [RadialSteps] with its colors scaled by the given factor.
  /// Since the alpha channel is what receives the scale factor,
  /// `0.0` or less results in a gradient that is fully transparent.
  @override
  RadialSteps scale(double factor) => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, factor)!)
            .toList(),
      );

  @override
  Gradient? lerpFrom(Gradient? a, double t) => (a == null || (a is RadialSteps))
      ? RadialSteps.lerp(a as RadialSteps?, this, t)
      : super.lerpFrom(a, t);

  @override
  Gradient? lerpTo(Gradient? b, double t) => (b == null || (b is RadialSteps))
      ? RadialSteps.lerp(this, b as RadialSteps?, t)
      : super.lerpTo(b, t);

  /// Linearly interpolate between two [RadialSteps]s.
  ///
  /// If either gradient is null, this function linearly interpolates from a
  /// a gradient that matches the other gradient in [center], [radius], [stops]
  /// and [tileMode] and with the same [colors] but transparent (using [scale]).
  ///
  /// If neither gradient is null, they must have the same number of [colors].
  ///
  /// The `t` argument represents a position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as `Curves.elasticInOut`).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an `AnimationController`.
  static RadialSteps? lerp(RadialSteps? a, RadialSteps? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!.scale(t);
    if (b == null) return a.scale(1.0 - t);
    final interpolated = PrimitiveGradient.interpolateFrom(a, b, t);
    return RadialSteps(
      softness: ui.lerpDouble(a.softness, b.softness, t) ?? 0,
      colors: interpolated.colors,
      stops: interpolated.stops,
      // TODO: Interpolate Matrix4 / GradientTransform
      transform: t > 0.5 ? a.transform : b.transform,
      // TODO: interpolate tile mode
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
      center: AlignmentGeometry.lerp(a.center, b.center, t)!,
      radius: math.max(0.0, ui.lerpDouble(a.radius, b.radius, t)!),
      focal: AlignmentGeometry.lerp(a.focal, b.focal, t),
      focalRadius:
          math.max(0.0, ui.lerpDouble(a.focalRadius, b.focalRadius, t)!),
    );
  }

  /// 📋 Returns a new copy of this `RadialSteps` with any provided
  /// optional parameters overriding those of `this`.
  RadialSteps copyWith({
    double? softness,
    List<Color>? colors,
    List<double>? stops,
    TileMode? tileMode,
    AlignmentGeometry? center,
    double? radius,
    AlignmentGeometry? focal,
    double? focalRadius,
    GradientTransform? transform,
  }) =>
      RadialSteps(
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        center: center ?? this.center,
        radius: radius ?? this.radius,
        focal: focal ?? this.focal,
        focalRadius: focalRadius ?? this.focalRadius,
      );

  @override
  bool operator ==(Object other) => (identical(this, other))
      ? true
      : (other.runtimeType != runtimeType)
          ? false
          : other is RadialSteps &&
              other.softness == softness &&
              listEquals<Color>(other.colors, colors) &&
              listEquals<double>(other.stops, stops) &&
              other.tileMode == tileMode &&
              other.center == center &&
              other.radius == radius &&
              other.focal == focal &&
              other.focalRadius == focalRadius;

  @override
  int get hashCode => hashValues(softness, hashList(colors), hashList(stops),
      tileMode, center, radius, focal, focalRadius);

  @override
  String toString() => '${objectRuntimeType(this, 'RadialSteps')}'
      '($softness, resolved colors: $colors, resolved stops: $stops, '
      '$tileMode, $center, $radius, $focal, $focalRadius)';
}

class SweepSteps extends Steps {
  const SweepSteps({
    double softness = 0.0,
    required List<Color> colors,
    List<double>? stops,
    this.tileMode = TileMode.clamp,
    this.center = Alignment.center,
    this.startAngle = 0.0,
    this.endAngle = math.pi * 2,
    GradientTransform? transform,
  }) : super(
          softness: softness,
          colors: colors,
          stops: stops,
          transform: transform,
        );

  final TileMode tileMode;
  final AlignmentGeometry center;
  final double startAngle;
  final double endAngle;

  /// Creates a `ui.Gradient.sweep` with duplicated `colors` and `stops`.
  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) =>
      SweepGradient(
        colors: steppedColors,
        stops: steppedStops,
        transform: transform,
        tileMode: tileMode,
        center: center,
        startAngle: startAngle,
        endAngle: endAngle,
      ).createShader(rect, textDirection: textDirection);

  /// Returns a new [SweepSteps] with its colors scaled by the given factor.
  /// Since the alpha channel is what receives the scale factor,
  /// `0.0` or less results in a gradient that is fully transparent.
  @override
  SweepSteps scale(double factor) => copyWith(
        colors: colors
            .map<Color>((Color color) => Color.lerp(null, color, factor)!)
            .toList(),
      );

  @override
  Gradient? lerpFrom(Gradient? a, double t) => (a == null || (a is SweepSteps))
      ? SweepSteps.lerp(a as SweepSteps?, this, t)
      : super.lerpFrom(a, t);

  @override
  Gradient? lerpTo(Gradient? b, double t) => (b == null || (b is SweepSteps))
      ? SweepSteps.lerp(this, b as SweepSteps?, t)
      : super.lerpTo(b, t);

  /// Linearly interpolate between two [SweepSteps]s.
  ///
  /// If either gradient is null, then the non-null gradient is returned with
  /// its color scaled in the same way as the [scale] function.
  ///
  /// If neither gradient is null, they must have the same number of [colors].
  ///
  /// The `t` argument represents a position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as `Curves.elasticInOut`).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an `AnimationController`.
  static SweepSteps? lerp(SweepSteps? a, SweepSteps? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!.scale(t);
    if (b == null) return a.scale(1.0 - t);
    final interpolated = PrimitiveGradient.interpolateFrom(a, b, t);
    return SweepSteps(
      softness: ui.lerpDouble(a.softness, b.softness, t) ?? 0,
      colors: interpolated.colors,
      stops: interpolated.stops,
      // TODO: Interpolate Matrix4 / GradientTransform
      transform: t > 0.5 ? a.transform : b.transform,
      // TODO: interpolate tile mode
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
      center: AlignmentGeometry.lerp(a.center, b.center, t)!,
      startAngle: math.max(0.0, ui.lerpDouble(a.startAngle, b.startAngle, t)!),
      endAngle: math.max(0.0, ui.lerpDouble(a.endAngle, b.endAngle, t)!),
    );
  }

  /// 📋 Returns a new copy of this `SweepSteps` with any provided
  /// optional parameters overriding those of `this`.
  SweepSteps copyWith({
    double? softness,
    List<Color>? colors,
    List<double>? stops,
    TileMode? tileMode,
    AlignmentGeometry? center,
    double? startAngle,
    double? endAngle,
    GradientTransform? transform,
  }) =>
      SweepSteps(
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        center: center ?? this.center,
        startAngle: startAngle ?? this.startAngle,
        endAngle: endAngle ?? this.endAngle,
        tileMode: tileMode ?? this.tileMode,
        transform: transform ?? this.transform,
      );

  @override
  bool operator ==(Object other) => (identical(this, other))
      ? true
      : (other.runtimeType != runtimeType)
          ? false
          : other is SweepSteps &&
              other.softness == softness &&
              listEquals<Color>(other.colors, colors) &&
              listEquals<double>(other.stops, stops) &&
              other.center == center &&
              other.startAngle == startAngle &&
              other.endAngle == endAngle &&
              other.tileMode == tileMode;

  @override
  int get hashCode => hashValues(softness, hashList(colors), hashList(stops),
      tileMode, center, startAngle, endAngle);

  @override
  String toString() => '${objectRuntimeType(this, 'SweepSteps')}'
      '($softness, resolved colors: $colors, resolved stops: $stops, '
      '$tileMode, $center, $startAngle, $endAngle)';
}
