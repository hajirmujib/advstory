import 'dart:async';
import 'dart:developer';

import 'package:advstory/advstory.dart';
import 'package:advstory/src/contants/enums.dart';
import 'package:advstory/src/contants/types.dart';
import 'package:advstory/src/controller/advstory_controller_impl.dart';
import 'package:advstory/src/util/build_helper.dart';
import 'package:advstory/src/view/components/tray/tray_animation_manager.dart';
import 'package:advstory/src/view/components/tray/tray_position_provider.dart';
import 'package:advstory/src/view/inherited_widgets/data_provider.dart';
import 'package:advstory/src/view/story_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds a tray list.
class TrayView extends StatefulWidget {
  const TrayView({
    required this.controller,
    required this.buildHelper,
    required this.preloadContent,
    required this.preloadStory,
    required this.style,
    required this.myStoryLength,
    required this.buildStoryOnTrayScroll,
    required this.trayBuilder,
    this.onTapEmptyStory,
    Key? key,
  }) : super(key: key);

  /// Helper for story builds.
  final BuildHelper buildHelper;
  final VoidCallback? onTapEmptyStory;

  /// {@macro advstory.storyController}
  final AdvStoryControllerImpl controller;

  final int myStoryLength;

  /// {@macro advstory.preloadContent}
  final bool preloadContent;

  /// {@macro advstory.preloadStory}
  final bool preloadStory;

  /// {@macro advstory.style}
  final AdvStoryStyle style;

  /// {@macro advstory.trayBuilder}
  final TrayBuilder trayBuilder;

  /// {@macro advstory.buildStoryOnTrayScroll}
  final bool buildStoryOnTrayScroll;

  @override
  State<TrayView> createState() => _TrayViewState();
}

class _TrayViewState extends State<TrayView> with TickerProviderStateMixin {
  /// Controls story view position.
  late final AnimationController _posController;
  TrayAnimationManager? _trayAnimationManager;

  /// Used to determine whether a story can be shown or not.
  bool _canShowStory = true;
  final bool _hideLoader = false;

  /// Opens story view and notifies listeners
  void _show(
    Widget view,
    BuildContext context,
    int index,
    Widget tray,
  ) async {
    _canShowStory = true;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      barrierLabel: 'Stories',
      pageBuilder: (_, __, ___) => view,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (c, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.linearToEaseOut,
            ),
          ),
          child: child,
        );
      },
    );
    // Navigator.push(context, MaterialPageRoute(builder: (context) {
    //   return StoryViewPage(
    //     child: view,
    //   );
    // }));

    widget.controller.notifyListeners(
      StoryEvent.trayTap,
      storyIndex: index,
      contentIndex: 0,
    );
    log('notify');
  }

  Future<void> _handleTrayTap({
    required BuildContext context,
    required Widget tray,
    required int index,
  }) async {
    log('_handleTrayTap');
    log('_hideLoader _handleTrayTap $_hideLoader');

    if (!_canShowStory) return;

    bool isAnimated = tray is TrayPositionProvider;
    final pos = widget.controller.trayTapInterceptor?.call(index) ??
        StoryPosition(0, index);

    if (isAnimated) {
      _trayAnimationManager!.update(shouldAnimate: true, index: index);
    }

    _posController.reset();
    _canShowStory = false;
    widget.controller.positionNotifier
      ..trayWillAnimate = isAnimated
      ..initialPosition = pos
      ..update(story: pos.story, content: pos.content);
    final firstContentPreperation = isAnimated ? Completer<void>() : null;

    final posAnim = Tween<Offset>(
      begin: Offset(0, MediaQuery.of(context).size.height * 1.2),
      end: Offset.zero,
    ).animate(_posController);

    // Set story PageController to start from the given index.
    widget.controller.storyController = PageController(initialPage: pos.story);
    _show(
        SlideTransition(
          position: posAnim,
          child: DataProvider(
            controller: widget.controller,
            buildHelper: widget.buildHelper,
            style: widget.style,
            preloadStory: widget.preloadStory,
            preloadContent: widget.preloadContent,
            firstContentPreperation: firstContentPreperation,
            child: const StoryView(),
          ),
        ),
        context,
        pos.story,
        tray);

    // SchedulerBinding.instance.addPostFrameCallback((_) async {
    if (isAnimated) {
      final story = await widget.buildHelper.buildStory(pos.story);
      final content = story.contentBuilder(0);

      if (content is! SimpleCustomContent) {
        // Handle jumps before story view opens
        final posNotifier = widget.controller.positionNotifier;
        if (posNotifier.story != pos.story || posNotifier.content != 0) {
          firstContentPreperation!.complete();
        } else {
          // If position not changed, wait content preperation.
          await firstContentPreperation!.future;
        }
      }

      _trayAnimationManager!.update(shouldAnimate: false, index: index);
    }

    if (widget.style.hideBars) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }

    _posController.forward();
    //   // widget.controller.positionNotifier.update(status: StoryStatus.play);

    //   Future.delayed(const Duration(milliseconds: 300), () {
    //     log('SchedulerBinding milliseconds');

    widget.controller.positionNotifier.update(status: StoryStatus.play);
    //   });
    //   log('SchedulerBinding');
    // });
  }

  @override
  void initState() {
    _posController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    super.initState();
  }

  @override
  void dispose() {
    _posController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _trayAnimationManager ??= TrayAnimationManager(
      child: ListView.separated(
        padding: widget.style.trayListStyle.padding,
        scrollDirection: widget.style.trayListStyle.direction,
        itemCount: widget.controller.storyCount,
        itemBuilder: (context, index) {
          if (widget.buildStoryOnTrayScroll) {
            widget.buildHelper.prepareStory(index);
          }

          Widget tray = widget.trayBuilder(index);
          if (tray is AnimatedTray) {
            tray = TrayPositionProvider(
              index: index,
              child: tray,
            );
          }

          return GestureDetector(
            onTap: () async {
              if (widget.myStoryLength == 0 && index == 0) {
                if (widget.onTapEmptyStory != null) {
                  widget.onTapEmptyStory!();
                }
              } else {
                _handleTrayTap(
                  context: context,
                  tray: tray,
                  index: index,
                );
              }
              // if (widget.myStoryLength == 0) {
              //   if (widget.onTapEmptyStory != null) {
              //     widget.onTapEmptyStory!();
              //   }
              // } else {
              //   _handleTrayTap(
              //     context: context,
              //     tray: tray,
              //     index: index,
              //   );
              // }
            },
            child: tray,
          );
        },
        separatorBuilder: (context, index) => SizedBox(
          width: widget.style.trayListStyle.direction == Axis.vertical
              ? 0
              : widget.style.trayListStyle.spacing,
          height: widget.style.trayListStyle.direction == Axis.horizontal
              ? 0
              : widget.style.trayListStyle.spacing,
        ),
      ),
    );
  }
}
