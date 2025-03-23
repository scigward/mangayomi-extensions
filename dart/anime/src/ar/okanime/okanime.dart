import 'package:mangayomi/bridge_lib.dart';

class OkAnime extends MProvider {
  OkAnime({required this.source});

  MSource source;
  final Client client = Client(source);

  @override
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse(source.baseUrl))).body;
    List<MManga> animeList = [];
    String path =
        '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]';
    final urls = xpath(res, '$path/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res, '$path/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res, '$path/div[@class="anime-image")]/img/@src');
    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    return MPages(animeList, false);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(
      Uri.parse("${source.baseUrl}/espisode-list?page=$page"),
    ))
        .body;
    List<MManga> animeList = [];
    String path = '//*[contains(@class,"anime-card")]';
    final urls = xpath(res, '$path/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res, '$path/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res, '$path/div[@class="episode-image")]/img/@src');
    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(
      res,
      '//li[@class="page-item"]/a[@rel="next"]/@href',
    );
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    String url = "${source.baseUrl}/search/?s=$query";
    if (page > 1) {
      url += "&page=$page";
    }
    final res = (await client.get(Uri.parse(url))).body;
    List<MManga> animeList = [];
    String path = '//*[contains(@class,"anime-card")]';
    final urls = xpath(res, '$path/div[@class="anime-title")]/h4/a/@href');
    final names = xpath(res, '$path/div[@class="anime-title")]/h4/a/text()');
    final images = xpath(res, '$path/div[@class="anime-image")]/img/@src');
    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i];
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(
      res,
      '//li[@class="page-item"]/a[@rel="next"]/@href',
    );
    return MPages(animeList, nextPage.isNotEmpty);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    MManga anime = MManga();
    anime.description = xpath(res, '//*[@class="review-content"]/text()').first;
    anime.genre = xpath(res, '//*[@class="review-author-info"]/a/text()');
    final epUrls = xpath(
      res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/@href',
    ).reversed.toList();
    final names = xpath(
      res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/text()',
    ).reversed.toList();
    List<MChapter>? episodesList = [];
    for (var i = 0; i < epUrls.length; i++) {
      MChapter episode = MChapter();
      episode.name = names[i];
      episode.url = epUrls[i];
      episodesList.add(episode);
    }
    anime.chapters = episodesList;
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final res = (await client.get(Uri.parse(url))).body;
    final urls = xpath(res, '//*[@id="streamlinks"]/a/@data-src');
    final qualities = xpath(res, '//*[@id="streamlinks"]/a/span/text()');
    final hosterSelection = preferenceHosterSelection(source.id);
    List<MVideo> videos = [];
    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      final quality = getQuality(qualities[i]);
      List<MVideo> a = [];
      if (url.contains("https://doo") &&
          hosterSelection.contains("Dood")) {
        a = await doodExtractor(url, "DoodStream - $quality");
      } else if (url.contains("mp4upload") &&
          hosterSelection.contains("Mp4upload")) {
        a = await mp4UploadExtractor(url, null, "", "");
      } else if (url.contains("ok.ru") &&
          hosterSelection.contains("Okru")) {
        a = await okruExtractor(url);
      } else if (url.contains("voe.sx") &&
          hosterSelection.contains("Voe")) {
        a = await voeExtractor(url, "VoeSX $quality");
      } else if (containsVidBom(url) &&
          hosterSelection.contains("VidBom")) {
        a = await vidBomExtractor(url);
      } else if (url.contains("mega.nz") &&
          hosterSelection.contains("Mega")) {
        a = await megaExtractor(url, "Mega - $quality");
      } else if (url.contains("drive.google.com") &&
          hosterSelection.contains("Google Drive")) {
        a = await googleDriveExtractor(url, "Google Drive - $quality");
      } else if (url.contains("mochi") &&
          hosterSelection.contains("Mochi")) {
        a = await mochiExtractor(url, "Mochi - $quality");
      } else if (url.contains("yourupload") &&
          hosterSelection.contains("YourUpload")) {
        a = await yourUploadExtractor(url, "YourUpload - $quality");
      } else if (url.contains("vk.com") &&
          hosterSelection.contains("VK")) {
        a = await vkExtractor(url, "VK - $quality");
      }
      videos.addAll(a);
    }
    return videos;
  }
}
