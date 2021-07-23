/// Provides utilities for copying `Gradient`s & more
/// - [LinearGradientUtils] - 📋 `copyWith`
/// - [RadialGradientUtils] - 📋 `copyWith`
/// - [SweepGradientUtils] - 📋 `copyWith`
/// - [GradientUtils]
///   - 📋 `copyWith`
///   - Global getters for the properties available from every type,
///   with default fallback values if `this` gradient does not have that prop.
///   - Getter `Gradient.reversed`, returning a `Gradient` with reversed
///   colors (and stops, if explicit).
///   - Method `Gradient.animate`, returning the [AnimatedGradient.observe]
///   animated `Gradient` from an `AnimatedGradient` constructed by `this`
///   gradient and the method parameters.
library spectrum;

import 'animation.dart';
import 'common.dart';
import 'interpolation.dart';
import 'models.dart';
import 'steps.dart';
import 'steps_shaded.dart';
import 'tween.dart';

/// {@template GradientCopyWith}
/// Provision of a function type defintion for the purpose of allowing
/// the override of this package's default `copyWith()` method.
///
/// The default `GradientCopyWith` for this package is [spectrumCopyWith], a
/// wrapper for [GradientUtils] extension method `Gradient.copyWith`.
///
/// Imagine for a a bespoke `Gradient` type from a source other than those
/// recognized by this package, an overridden `GradientCopyWith` \
/// (say like the one requested by [GradientTween._copyWith], itself forwarding
/// that function to [IntermediateGradient._copyWith]) \
/// could be used to ensure that the inner workings of the `Gradient`
/// interpolation return back the correct, custom `Gradient`.
///
/// ---
/// Such as:
///
///     Gradient customCopyWith(Gradient original, { List<Color>? colors, List<double>? stops, . . . /* optionals */ })
///         => CustomGradient(
///              colors: colors ?? original.colors,
///              stops: stops ?? original.stops,
///              . . . );
/// ---
///     final tween = GradientTween(
///       begin: customGradient,
///       end: differentCustomGradient,
///       overrideCopyWith: customCopyWith);
/// {@endtemplate}
typedef GradientCopyWith = Gradient Function(
  Gradient gradient, {
  // Universal
  List<Color>? colors,
  List<double>? stops,
  GradientTransform? transform,
  TileMode? tileMode,
  // Linear
  AlignmentGeometry? begin,
  AlignmentGeometry? end,
  // Radial or Sweep
  AlignmentGeometry? center,
  // Radial
  double? radius,
  AlignmentGeometry? focal,
  double? focalRadius,
  // Sweep
  double? startAngle,
  double? endAngle,
  // Steps
  double? softness,
  // Shaded Steps
  ColorArithmetic? shadeFunction,
  num? shadeFactor,
  double? distance,
});

/// Offers [copyWith] method to make duplicate `Gradient`s.
extension LinearGradientUtils on LinearGradient {
  /// 📋 Returns a new copy of this `LinearGradient` with any provided
  /// optional parameters overriding those of `this`.
  LinearGradient copyWith({
    List<Color>? colors,
    List<double>? stops,
    GradientTransform? transform,
    TileMode? tileMode,
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
  }) =>
      LinearGradient(
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        begin: begin ?? this.begin,
        end: end ?? this.end,
      );
}

/// Offers [copyWith] method to make duplicate `Gradient`s.
extension RadialGradientUtils on RadialGradient {
  /// 📋 Returns a new copy of this `RadialGradient` with any provided
  /// optional parameters overriding those of `this`.
  RadialGradient copyWith({
    List<Color>? colors,
    List<double>? stops,
    GradientTransform? transform,
    TileMode? tileMode,
    AlignmentGeometry? center,
    double? radius,
    AlignmentGeometry? focal,
    double? focalRadius,
  }) =>
      RadialGradient(
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        center: center ?? this.center,
        radius: radius ?? this.radius,
        focal: focal ?? this.focal,
        focalRadius: focalRadius ?? this.focalRadius,
      );
}

/// Offers [copyWith] method to make duplicate `Gradient`s.
extension SweepGradientUtils on SweepGradient {
  /// 📋 Returns a new copy of this `SweepGradient` with any provided
  /// optional parameters overriding those of `this`.
  SweepGradient copyWith({
    List<Color>? colors,
    List<double>? stops,
    GradientTransform? transform,
    TileMode? tileMode,
    AlignmentGeometry? center,
    double? startAngle,
    double? endAngle,
  }) =>
      SweepGradient(
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        center: center ?? this.center,
        startAngle: startAngle ?? this.startAngle,
        endAngle: endAngle ?? this.endAngle,
      );
}

/// Offers [copyWith] method to make duplicate `Gradient`s as well as global
/// getters for any [Gradient] with specific fallbacks; [reversed] to
/// easily return a `Gradient` with its colors reversed; and [animate], as a
/// shortcut to provide `this` [Gradient] as an [AnimatedGradient]'s source
/// and return the [AnimatedGradient.observe] output.
extension GradientUtils on Gradient {
  /// Returns a copy of this `Gradient` with its `List<Color>` [colors] reversed
  /// as well as any potential stops.
  Gradient get reversed => copyWith(
        colors: colors.reversed.toList(),
        stops: stops?.reversed.toList(),
      );

  /// Returns the [AnimatedGradient.observe] animated `Gradient` output from
  /// a [new AnimatedGradient] constructed by `this` `Gradient` and the
  /// provided parameters.
  ///
  /// Provide a `Tween<double>().animate()` or an [AnimationController]
  /// as `controller` to drive the flow of the animation. Consider
  /// driving the [AnimationController] by `controller.repeat(reverse:true)`.
  ///
  /// The default `style` is [GradientAnimation.colorArithmetic], which looks to
  /// parameter `colorShading` for the function to invoke.
  ///
  /// The default `colorShading` is [Shades.withOpacity] which applies the
  /// clamped animation value as each gradient color's opacity, between `0..1`.
  ///
  /// If `style == GradientAnimation.stopsArithmetic`, then function
  /// `stopsArithmetic` applies the animation transformation.
  /// Default is [Maths.subtraction].
  Gradient animate({
    required Animation<double> controller,
    GradientStoryboard storyboard = AnimatedGradient.defaultStoryboard,
    // GradientAnimation style = GradientAnimation.colorArithmetic,
    // required GradientAnimation style,
    // ColorArithmetic colorShading = Shades.withOpacity,
    // StopsArithmetic stopsArithmetic = Maths.subtraction,
    // TweenSpec tweenSpec = const {},
    GradientCopyWith overrideCopyWith = spectrumCopyWith,
  }) =>
      AnimatedGradient(
        gradient: this,
        controller: controller,
        storyboard: storyboard,
        // style: style,
        // colorArithmetic: colorShading,
        // stopsArithmetic: stopsArithmetic,
        // tweenSpec: tweenSpec,
        overrideCopyWith: overrideCopyWith,
      ).observe;

  /// 📋 Returns a new copy of this `Gradient` with any appropriate
  /// optional parameters overriding those of `this`.
  ///
  /// Recognizes [LinearGradient], [RadialGradient], & [SweepGradient],
  /// as well as this package's [LinearSteps], [RadialSteps], & [SweepSteps].
  ///
  /// Defaults back to [RadialGradient] if `Type` cannot be matched.
  /// (Radial is simply a design choice.)
  ///
  /// ```dart
  /// Gradient copyWith({
  ///   // Universal
  // ignore: lines_longer_than_80_chars
  ///   List<Color>? colors, List<double>? stops, GradientTransform? transform, TileMode? tileMode,
  ///   // Linear
  ///   AlignmentGeometry? begin, AlignmentGeometry? end,
  ///   // Radial or Sweep
  ///   AlignmentGeometry? center,
  ///   // Radial
  ///   double? radius, AlignmentGeometry? focal, double? focalRadius,
  ///   // Sweep
  ///   double? startAngle, double? endAngle,
  ///   // Steps
  ///   double? softness
  ///   // Shaded Steps
  ///   ColorArithmetic? shadeFunction, int? shadeFactor, double? distance
  /// })
  /// ```
  Gradient copyWith({
    // Universal
    List<Color>? colors,
    List<double>? stops,
    GradientTransform? transform,
    TileMode? tileMode,
    // Linear
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
    // Radial or Sweep
    AlignmentGeometry? center,
    // Radial
    double? radius,
    AlignmentGeometry? focal,
    double? focalRadius,
    // Sweep
    double? startAngle,
    double? endAngle,
    // Steps
    double? softness,
    // Shaded Steps
    ColorArithmetic? shadeFunction,
    num? shadeFactor,
    double? distance,
  }) {
    if (this is PrimitiveGradient) {
      return this;
    } else if (this is IntermediateGradient) {
      final copy = this as IntermediateGradient;
      return IntermediateGradient(
        copy.primitive,
        // Packets do not carry colors or stops
        GradientPacket(
          copy.packet.a.copyWith(
            transform: transform ?? copy.packet.a.transform,
            tileMode: tileMode ?? copy.packet.a.tileMode,
            begin: begin ?? copy.packet.a.begin,
            end: end ?? copy.packet.a.end,
            center: center ?? copy.packet.a.center,
            radius: radius ?? copy.packet.a.radius,
            focal: focal ?? copy.packet.a.focal,
            focalRadius: focalRadius ?? copy.packet.a.focalRadius,
            startAngle: startAngle ?? copy.packet.a.startAngle,
            endAngle: endAngle ?? copy.packet.a.endAngle,
            softness: softness ?? copy.packet.a.softness,
            shadeFunction: shadeFunction ?? copy.packet.a.shadeFunction,
            shadeFactor: shadeFactor ?? copy.packet.a.shadeFactor,
            distance: distance ?? copy.packet.a.distance,
          ),
          copy.packet.b.copyWith(
            transform: transform ?? copy.packet.b.transform,
            tileMode: tileMode ?? copy.packet.b.tileMode,
            begin: begin ?? copy.packet.b.begin,
            end: end ?? copy.packet.b.end,
            center: center ?? copy.packet.b.center,
            radius: radius ?? copy.packet.b.radius,
            focal: focal ?? copy.packet.b.focal,
            focalRadius: focalRadius ?? copy.packet.b.focalRadius,
            startAngle: startAngle ?? copy.packet.b.startAngle,
            endAngle: endAngle ?? copy.packet.b.endAngle,
            softness: softness ?? copy.packet.b.softness,
            shadeFunction: shadeFunction ?? copy.packet.b.shadeFunction,
            shadeFactor: shadeFactor ?? copy.packet.b.shadeFactor,
            distance: distance ?? copy.packet.b.distance,
          ),
          copy.packet.t,
        ),
      );
    } else if (this is LinearGradient) {
      return LinearGradient(
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        begin: begin ?? this.begin,
        end: end ?? this.end,
      );
    } else if (this is SweepGradient) {
      return SweepGradient(
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        center: center ?? this.center,
        startAngle: startAngle ?? this.startAngle,
        endAngle: endAngle ?? this.endAngle,
      );
    } else if (this is LinearShadedSteps) {
      return LinearShadedSteps(
        shadeFunction: shadeFunction ?? this.shadeFunction,
        shadeFactor: shadeFactor ?? this.shadeFactor,
        distance: distance ?? this.distance,
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        begin: begin ?? this.begin,
        end: end ?? this.end,
      );
    } else if (this is RadialShadedSteps) {
      return RadialShadedSteps(
        shadeFunction: shadeFunction ?? this.shadeFunction,
        shadeFactor: shadeFactor ?? this.shadeFactor,
        distance: distance ?? this.distance,
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
    } else if (this is SweepShadedSteps) {
      return SweepShadedSteps(
        shadeFunction: shadeFunction ?? this.shadeFunction,
        shadeFactor: shadeFactor ?? this.shadeFactor,
        distance: distance ?? this.distance,
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        center: center ?? this.center,
        startAngle: startAngle ?? this.startAngle,
        endAngle: endAngle ?? this.endAngle,
      );
    } else if (this is LinearSteps) {
      return LinearSteps(
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        begin: begin ?? this.begin,
        end: end ?? this.end,
      );
    } else if (this is RadialSteps) {
      return RadialSteps(
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
    } else if (this is SweepSteps) {
      return SweepSteps(
        softness: softness ?? this.softness,
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        center: center ?? this.center,
        startAngle: startAngle ?? this.startAngle,
        endAngle: endAngle ?? this.endAngle,
      );
    } else {
      return RadialGradient(
        colors: colors ?? this.colors,
        stops: stops ?? this.stops,
        transform: transform ?? this.transform,
        tileMode: tileMode ?? this.tileMode,
        center: center ?? this.center,
        radius: radius ?? this.radius,
        focal: focal ?? this.focal,
        focalRadius: focalRadius ?? this.focalRadius,
      );
    }
  }

  //# UNIVERSAL

  /// How this `Gradient` tiles in the plane beyond the region before its
  /// starting stop and after its ending stop.
  ///
  /// For details, see [TileMode].
  ///
  /// ---
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_linear.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_linear.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_linear.png)
  /// ---
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_radial.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_radial.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_radial.png)
  ///
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_radialWithFocal.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_radialWithFocal.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_radialWithFocal.png)
  /// ---
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_clamp_sweep.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_mirror_sweep.png)
  /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/tile_mode_repeated_sweep.png)
  TileMode get tileMode => (this is IntermediateGradient)
      ? (this as IntermediateGradient).packet.tileMode
      : (this is LinearGradient)
          ? (this as LinearGradient).tileMode
          : (this is RadialGradient)
              ? (this as RadialGradient).tileMode
              : (this is SweepGradient)
                  ? (this as SweepGradient).tileMode
                  : (this is Steps)
                      ? (this as Steps).tileMode
                      : TileMode.clamp;

  //# LINEAR

  /// If this is a linear-type `Gradient`, returns `this.begin`.
  /// Otherwise the fallback retrun value is [Alignment.center].
  AlignmentGeometry get begin => (this is IntermediateGradient)
      ? (this as IntermediateGradient).packet.begin
      : (this is LinearGradient)
          ? (this as LinearGradient).begin
          : (this is LinearSteps)
              ? (this as LinearSteps).begin
              : Alignment.center;

  /// If this is a linear-type `Gradient`, returns `this.end`.
  /// Otherwise the fallback retrun value is [Alignment.center].
  AlignmentGeometry get end => (this is IntermediateGradient)
      ? (this as IntermediateGradient).packet.end
      : (this is LinearGradient)
          ? (this as LinearGradient).end
          : (this is LinearSteps)
              ? (this as LinearSteps).end
              : Alignment.center;

  //# RADIAL or SWEEP

  /// If this is a radial- or sweep-type `Gradient`, returns `this.center`.
  /// Otherwise the fallback retrun value is [Alignment.center].
  AlignmentGeometry get center => (this is IntermediateGradient)
      ? (this as IntermediateGradient).packet.center
      : (this is RadialGradient)
          ? (this as RadialGradient).center
          : (this is SweepGradient)
              ? (this as SweepGradient).center
              : (this is RadialSteps)
                  ? (this as RadialSteps).center
                  : (this is SweepSteps)
                      ? (this as SweepSteps).center
                      : Alignment.center;

  //# RADIAL

  /// If this is a radial-type `Gradient`, returns `this.radius`.
  /// Otherwise the fallback retrun value is `0.0`.
  double get radius => (this is IntermediateGradient)
      ? (this as IntermediateGradient).packet.radius
      : (this is RadialGradient)
          ? (this as RadialGradient).radius
          : (this is RadialSteps)
              ? (this as RadialSteps).radius
              : 0.0;

  /// If this is a radial-type `Gradient`, returns `this.focal`
  /// which may be `null`.
  /// Otherwise the fallback retrun value is `null`.
  AlignmentGeometry? get focal => (this is IntermediateGradient)
      ? (this as IntermediateGradient).packet.focal
      : (this is RadialGradient)
          ? (this as RadialGradient).focal
          : (this is RadialSteps)
              ? (this as RadialSteps).focal
              : null;

  /// If this is a radial-type `Gradient`, returns `this.focalRadius`.
  /// Otherwise the fallback retrun value is `0.0`.
  double get focalRadius => this is IntermediateGradient
      ? (this as IntermediateGradient).packet.focalRadius
      : this is RadialGradient
          ? (this as RadialGradient).focalRadius
          : this is RadialSteps
              ? (this as RadialSteps).focalRadius
              : 0.0;

  //# SWEEP

  /// If this is a sweep-type `Gradient`, returns `this.startAngle`.
  /// Otherwise the fallback retrun value is `0.0`.
  double get startAngle => this is IntermediateGradient
      ? (this as IntermediateGradient).packet.startAngle
      : this is SweepGradient
          ? (this as SweepGradient).startAngle
          : this is SweepSteps
              ? (this as SweepSteps).startAngle
              : 0.0;

  /// If this is a sweep-type `Gradient`, returns `this.endAngle`.
  /// Otherwise the fallback retrun value is `0.0`.
  double get endAngle => this is IntermediateGradient
      ? (this as IntermediateGradient).packet.endAngle
      : this is SweepGradient
          ? (this as SweepGradient).endAngle
          : this is SweepSteps
              ? (this as SweepSteps).endAngle
              : 0.0;

  //# STEPS

  /// If this is a [Steps]-type `Gradient`, returns `this.steppedColors`.
  /// Otherwise the fallback retrun value is [colors].
  List<Color> get steppedColors =>
      this is Steps ? (this as Steps).steppedColors : colors;

  /// If this is a [Steps]-type `Gradient`, returns `this.steppedStops`.
  /// Otherwise the fallback retrun value is [stops].
  List<double>? get steppedStops =>
      this is Steps ? (this as Steps).steppedStops : stops;

  /// If this is a [Steps]-type `Gradient`, returns `this.softness`.
  /// Otherwise the fallback retrun value is `0.0`.
  double get softness => this is IntermediateGradient
      ? (this as IntermediateGradient).packet.softness
      : this is Steps
          ? (this as Steps).softness
          : 0.0;

  //# SHADED STEPS

  /// If this is a `ShadedSteps`-type `Gradient`, returns `this.shadeFunction`.
  /// Otherwise the fallback retrun value is [Shades.withWhite].
  ColorArithmetic get shadeFunction => this is LinearShadedSteps
      ? (this as LinearShadedSteps).shadeFunction
      : this is RadialShadedSteps
          ? (this as RadialShadedSteps).shadeFunction
          : this is SweepShadedSteps
              ? (this as SweepShadedSteps).shadeFunction
              : Shades.withWhite;

  /// If this is a `ShadedSteps`-type `Gradient`, returns `this.shadeFactor`.
  /// Otherwise the fallback retrun value is `0`.
  num get shadeFactor => this is LinearShadedSteps
      ? (this as LinearShadedSteps).shadeFactor
      : this is RadialShadedSteps
          ? (this as RadialShadedSteps).shadeFactor
          : this is SweepShadedSteps
              ? (this as SweepShadedSteps).shadeFactor
              : 0;

  /// If this is a `ShadedSteps`-type `Gradient`, returns `this.distance`.
  /// Otherwise the fallback retrun value is `0.0`.
  double get distance => this is LinearShadedSteps
      ? (this as LinearShadedSteps).distance
      : this is RadialShadedSteps
          ? (this as RadialShadedSteps).distance
          : this is SweepShadedSteps
              ? (this as SweepShadedSteps).distance
              : 0.0;
}
