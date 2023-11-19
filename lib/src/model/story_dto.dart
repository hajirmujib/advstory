import 'dart:typed_data';

class StoryDto {
  String? storyUserid;
  String? avatarUrl;
  String? firstName;
  String? lastName;
  bool? isMyStory;
  String? cover;
  Uint8List? bgVideo;
  List<Visited>? visited;

  StoryDto(
      {this.storyUserid,
      this.isMyStory,
      this.avatarUrl,
      this.bgVideo,
      this.firstName,
      this.lastName,
      this.cover,
      this.visited});

  StoryDto.fromJson(Map<String, dynamic> json) {
    isMyStory = json['is_myStory'];
    storyUserid = json['story_userid'];
    avatarUrl = json['avatar_url'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    bgVideo = json['bg_video'];
    cover = json['cover'];
    if (json['visited'] != null) {
      visited = <Visited>[];
      json['visited'].forEach((v) {
        visited!.add(Visited.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_myStory'] = isMyStory;
    data['story_userid'] = storyUserid;
    data['avatar_url'] = avatarUrl;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['cover'] = cover;
    if (visited != null) {
      data['visited'] = visited!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Visited {
  String? storyId;
  String? storyVideoFile;
  String? storyUserid;
  String? storyDatetime;

  Visited(
      {this.storyId,
      this.storyVideoFile,
      this.storyUserid,
      this.storyDatetime});

  Visited.fromJson(Map<String, dynamic> json) {
    storyId = json['story_id'];
    storyVideoFile = json['story_video_file'];
    storyUserid = json['story_userid'];
    storyDatetime = json['story_datetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['story_id'] = storyId;
    data['story_video_file'] = storyVideoFile;
    data['story_userid'] = storyUserid;
    data['story_datetime'] = storyDatetime;
    return data;
  }
}
