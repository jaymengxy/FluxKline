import 'dart:math' as math;

import 'package:flutter/gestures.dart';

enum _ScaleState {
  ready,
  possible,
  accepted,
  started,
}

bool _isFlingGesture(Velocity velocity) {
  final speedSquared = velocity.pixelsPerSecond.distanceSquared;
  return speedSquared > kMinFlingVelocity * kMinFlingVelocity;
}

class _LineBetweenPointers {
  _LineBetweenPointers({
    this.pointerStartLocation = Offset.zero,
    this.pointerStartId = 0,
    this.pointerEndLocation = Offset.zero,
    this.pointerEndId = 1,
  }) : assert(pointerStartId != pointerEndId, 'startId has to be different from endId');

  final Offset pointerStartLocation;
  final int pointerStartId;
  final Offset pointerEndLocation;
  final int pointerEndId;
}

class KLineGestureRecognizer extends OneSequenceGestureRecognizer {
  KLineGestureRecognizer({
    super.debugOwner,
    this.dragStartBehavior = DragStartBehavior.down,
  });

  bool enableVerDrag = false;

  DragStartBehavior dragStartBehavior;

  GestureScaleStartCallback? onStart;

  GestureScaleUpdateCallback? onUpdate;

  GestureScaleEndCallback? onEnd;

  _ScaleState _state = _ScaleState.ready;

  Matrix4? _lastTransform;

  late Offset _initialFocalPoint;
  late Offset _currentFocalPoint;
  late double _initialSpan;
  late double _currentSpan;
  late double _initialHorizontalSpan;
  late double _currentHorizontalSpan;
  late double _initialVerticalSpan;
  late double _currentVerticalSpan;
  _LineBetweenPointers? _initialLine;
  _LineBetweenPointers? _currentLine;
  late Map<int, Offset> _pointerLocations;
  late List<int> _pointerQueue;
  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};

  double get _scaleFactor => _initialSpan > 0.0 ? _currentSpan / _initialSpan : 1.0;

  double get _horizontalScaleFactor =>
      _initialHorizontalSpan > 0.0 ? _currentHorizontalSpan / _initialHorizontalSpan : 1.0;

  double get _verticalScaleFactor =>
      _initialVerticalSpan > 0.0 ? _currentVerticalSpan / _initialVerticalSpan : 1.0;

  double _computeRotationFactor() {
    if (_initialLine == null || _currentLine == null) {
      return 0;
    }
    final fx = _initialLine!.pointerStartLocation.dx;
    final fy = _initialLine!.pointerStartLocation.dy;
    final sx = _initialLine!.pointerEndLocation.dx;
    final sy = _initialLine!.pointerEndLocation.dy;

    final nfx = _currentLine!.pointerStartLocation.dx;
    final nfy = _currentLine!.pointerStartLocation.dy;
    final nsx = _currentLine!.pointerEndLocation.dx;
    final nsy = _currentLine!.pointerEndLocation.dy;

    final angle1 = math.atan2(fy - sy, fx - sx);
    final angle2 = math.atan2(nfy - nsy, nfx - nsx);

    return angle2 - angle1;
  }

  @override
  void addAllowedPointer(PointerEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    _velocityTrackers[event.pointer] = VelocityTracker.withKind(event.kind);
    if (_state == _ScaleState.ready) {
      _state = _ScaleState.possible;
      _initialSpan = 0.0;
      _currentSpan = 0.0;
      _initialHorizontalSpan = 0.0;
      _currentHorizontalSpan = 0.0;
      _initialVerticalSpan = 0.0;
      _currentVerticalSpan = 0.0;
      _pointerLocations = <int, Offset>{};
      _pointerQueue = <int>[];
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _ScaleState.ready, '');
    var didChangeConfiguration = false;
    var shouldStartIfAccepted = false;
    if (event is PointerMoveEvent) {
      final tracker = _velocityTrackers[event.pointer]!;
      if (!event.synthesized) {
        tracker.addPosition(event.timeStamp, event.position);
      }
      _pointerLocations[event.pointer] = event.position;
      shouldStartIfAccepted = true;
      _lastTransform = event.transform;
    } else if (event is PointerDownEvent) {
      _pointerLocations[event.pointer] = event.position;
      _pointerQueue.add(event.pointer);
      didChangeConfiguration = true;
      shouldStartIfAccepted = true;
      _lastTransform = event.transform;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerLocations.remove(event.pointer);
      _pointerQueue.remove(event.pointer);
      didChangeConfiguration = true;
      _lastTransform = event.transform;
    }

    _updateLines();
    _update();

    if (!didChangeConfiguration || _reconfigure(event.pointer)) {
      _advanceStateMachine(shouldStartIfAccepted, event.kind);
    }

    stopTrackingIfPointerNoLongerDown(event);
  }

  void _update() {
    final count = _pointerLocations.keys.length;

    var focalPoint = Offset.zero;
    for (final pointer in _pointerLocations.keys) {
      focalPoint += _pointerLocations[pointer]!;
    }
    _currentFocalPoint = count > 0 ? focalPoint / count.toDouble() : Offset.zero;

    var totalDeviation = 0.0;
    var totalHorizontalDeviation = 0.0;
    var totalVerticalDeviation = 0.0;
    for (final pointer in _pointerLocations.keys) {
      totalDeviation += (_currentFocalPoint - _pointerLocations[pointer]!).distance;
      totalHorizontalDeviation += (_currentFocalPoint.dx - _pointerLocations[pointer]!.dx).abs();
      totalVerticalDeviation += (_currentFocalPoint.dy - _pointerLocations[pointer]!.dy).abs();
    }
    _currentSpan = count > 0 ? totalDeviation / count : 0.0;
    _currentHorizontalSpan = count > 0 ? totalHorizontalDeviation / count : 0.0;
    _currentVerticalSpan = count > 0 ? totalVerticalDeviation / count : 0.0;
  }

  void _updateLines() {
    final count = _pointerLocations.keys.length;
    assert(_pointerQueue.length >= count, '');

    if (count < 2) {
      _initialLine = _currentLine;
    } else if (_initialLine != null &&
        _initialLine!.pointerStartId == _pointerQueue[0] &&
        _initialLine!.pointerEndId == _pointerQueue[1]) {
      _currentLine = _LineBetweenPointers(
        pointerStartId: _pointerQueue[0],
        pointerStartLocation: _pointerLocations[_pointerQueue[0]]!,
        pointerEndId: _pointerQueue[1],
        pointerEndLocation: _pointerLocations[_pointerQueue[1]]!,
      );
    } else {
      _initialLine = _LineBetweenPointers(
        pointerStartId: _pointerQueue[0],
        pointerStartLocation: _pointerLocations[_pointerQueue[0]]!,
        pointerEndId: _pointerQueue[1],
        pointerEndLocation: _pointerLocations[_pointerQueue[1]]!,
      );
      _currentLine = null;
    }
  }

  bool _reconfigure(int pointer) {
    _initialFocalPoint = _currentFocalPoint;
    _initialSpan = _currentSpan;
    _initialLine = _currentLine;
    _initialHorizontalSpan = _currentHorizontalSpan;
    _initialVerticalSpan = _currentVerticalSpan;
    if (_state == _ScaleState.started) {
      if (onEnd != null) {
        final tracker = _velocityTrackers[pointer]!;

        var velocity = tracker.getVelocity();
        if (_isFlingGesture(velocity)) {
          final pixelsPerSecond = velocity.pixelsPerSecond;
          if (pixelsPerSecond.distanceSquared > kMaxFlingVelocity * kMaxFlingVelocity) {
            velocity = Velocity(
              pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * kMaxFlingVelocity,
            );
          }
          invokeCallback<void>(
            'onEnd',
            () => onEnd!(
              ScaleEndDetails(velocity: velocity, pointerCount: _pointerQueue.length),
            ),
          );
        } else {
          invokeCallback<void>(
            'onEnd',
            () => onEnd!(
              ScaleEndDetails(pointerCount: _pointerQueue.length),
            ),
          );
        }
      }
      _state = _ScaleState.accepted;
      return false;
    }
    return true;
  }

  void _advanceStateMachine(bool shouldStartIfAccepted, PointerDeviceKind pointerDeviceKind) {
    if (_state == _ScaleState.ready) _state = _ScaleState.possible;

    if (_state == _ScaleState.possible) {
      final spanDelta = (_currentSpan - _initialSpan).abs();
      final pointDelta = _currentFocalPoint - _initialFocalPoint;
      if (spanDelta > computeScaleSlop(pointerDeviceKind)) {
        resolve(GestureDisposition.accepted);
      } else if (pointDelta.dx.abs() > pointDelta.dy.abs() && pointDelta.distance > 6) {
        resolve(GestureDisposition.accepted);
      } else if (enableVerDrag && pointDelta.distance > computeScaleSlop(pointerDeviceKind)) {
        resolve(GestureDisposition.accepted);
      }
    } else if (_state.index >= _ScaleState.accepted.index) {
      resolve(GestureDisposition.accepted);
    }

    if (_state == _ScaleState.accepted && shouldStartIfAccepted) {
      _state = _ScaleState.started;
      _dispatchOnStartCallbackIfNeeded();
    }

    if (_state == _ScaleState.started && onUpdate != null) {
      invokeCallback<void>('onUpdate', () {
        onUpdate!(
          ScaleUpdateDetails(
            scale: _scaleFactor,
            horizontalScale: _horizontalScaleFactor,
            verticalScale: _verticalScaleFactor,
            focalPoint: _currentFocalPoint,
            localFocalPoint: PointerEvent.transformPosition(_lastTransform, _currentFocalPoint),
            rotation: _computeRotationFactor(),
            pointerCount: _pointerQueue.length,
          ),
        );
      });
    }
  }

  void _dispatchOnStartCallbackIfNeeded() {
    assert(_state == _ScaleState.started, '');
    if (onStart != null) {
      invokeCallback<void>('onStart', () {
        onStart!(
          ScaleStartDetails(
            focalPoint: _currentFocalPoint,
            localFocalPoint: PointerEvent.transformPosition(
              _lastTransform,
              _currentFocalPoint,
            ),
            pointerCount: _pointerQueue.length,
          ),
        );
      });
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (_state == _ScaleState.possible) {
      _state = _ScaleState.started;
      _dispatchOnStartCallbackIfNeeded();
      if (dragStartBehavior == DragStartBehavior.start) {
        _initialFocalPoint = _currentFocalPoint;
        _initialSpan = _currentSpan;
        _initialLine = _currentLine;
        _initialHorizontalSpan = _currentHorizontalSpan;
        _initialVerticalSpan = _currentVerticalSpan;
      }
    }
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    switch (_state) {
      case _ScaleState.possible:
        resolve(GestureDisposition.rejected);
        break;
      case _ScaleState.ready:
        assert(false, 'we should have not seen a pointer yet');
        break;
      case _ScaleState.accepted:
        break;
      case _ScaleState.started:
        assert(false, 'we should be in the accepted state when user is done');
        break;
    }
    _state = _ScaleState.ready;
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }

  @override
  String get debugDescription => 'scale';
}
