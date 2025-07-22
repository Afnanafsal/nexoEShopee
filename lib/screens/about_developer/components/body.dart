import 'package:fishkart/constants.dart';
import 'package:fishkart/models/AppReview.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/app_review_database_helper.dart';
import 'package:fishkart/size_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_review_dialog.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(screenPadding),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(10)),
                Text("About Developer", style: headingStyle),
                SizedBox(height: getProportionateScreenHeight(50)),
                InkWell(
                  onTap: () async {
                    const String linkedInUrl =
                        "https://www.linkedin.com/in/afnanafsal";
                    await launchExternalUrl(linkedInUrl);
                  },
                  child: buildDeveloperAvatar(),
                ),
                SizedBox(height: getProportionateScreenHeight(30)),
                Text(
                  '" Afnan afsal "',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                Text(
                  "Flutter Developer",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: getProportionateScreenHeight(30)),
                Row(
                  children: [
                    Spacer(),
                    IconButton(
                      icon: SvgPicture.asset(
                        "assets/icons/github_icon.svg",
                        color: kTextColor.withOpacity(0.75),
                      ),
                      color: kTextColor.withOpacity(0.75),
                      iconSize: 40,
                      padding: EdgeInsets.all(16),
                      onPressed: () async {
                        const String githubUrl =
                            "https://github.com/afnanafsal";
                        await launchExternalUrl(githubUrl);
                      },
                    ),
                    IconButton(
                      icon: SvgPicture.asset(
                        "assets/icons/linkedin_icon.svg",
                        color: kTextColor.withOpacity(0.75),
                      ),
                      iconSize: 40,
                      padding: EdgeInsets.all(16),
                      onPressed: () async {
                        const String linkedInUrl =
                            "https://www.linkedin.com/in/afnanafsal";
                        await launchExternalUrl(linkedInUrl);
                      },
                    ),
                    IconButton(
                      icon: SvgPicture.asset(
                        "assets/icons/instagram_icon.svg",
                        color: kTextColor.withOpacity(0.75),
                      ),
                      iconSize: 40,
                      padding: EdgeInsets.all(16),
                      onPressed: () async {
                        const String instaUrl =
                            "https://www.instagram.com/afnnafsal/";
                        await launchExternalUrl(instaUrl);
                      },
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: getProportionateScreenHeight(50)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.thumb_up),
                      color: kTextColor.withOpacity(0.75),
                      iconSize: 50,
                      padding: EdgeInsets.all(16),
                      onPressed: () {
                        submitAppReview(context, liked: true);
                      },
                    ),
                    Text(
                      "Liked the app?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.thumb_down),
                      padding: EdgeInsets.all(16),
                      color: kTextColor.withOpacity(0.75),
                      iconSize: 50,
                      onPressed: () {
                        submitAppReview(context, liked: false);
                      },
                    ),
                    Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDeveloperAvatar() {
    // For developer avatar, we'll use a default asset image or placeholder
    return CircleAvatar(
      radius: SizeConfig.screenWidth * 0.3,
      backgroundColor: kTextColor.withOpacity(0.75),
      child: Icon(
        Icons.person,
        size: SizeConfig.screenWidth * 0.2,
        color: Colors.white,
      ),
    );
  }

  Future<void> launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Logger().i("$url URL was unable to launch");
      }
    } catch (e) {
      Logger().e("Exception while launching URL: $e");
    }
  }

  Future<void> submitAppReview(
    BuildContext context, {
    bool liked = true,
  }) async {
    AppReview? prevReview;
    try {
      prevReview = await AppReviewDatabaseHelper().getAppReviewOfCurrentUser();
    } on FirebaseException catch (e) {
      Logger().w("Firebase Exception: $e");
    } catch (e) {
      Logger().w("Unknown Exception: $e");
    } finally {
      if (prevReview == null) {
        prevReview = AppReview(
          AuthentificationService().currentUser.uid,
          liked: liked,
          feedback: "",
        );
      }
    }

    final AppReview result = await showDialog(
      context: context,
      builder: (context) {
        return AppReviewDialog(key: UniqueKey(), appReview: prevReview!);
      },
    );
    if (result != null) {
      result.liked = liked;
      bool reviewAdded = false;
      String snackbarMessage = "An unknown error occurred";
      try {
        reviewAdded = await AppReviewDatabaseHelper().editAppReview(result);
        if (reviewAdded) {
          snackbarMessage = "Feedback submitted successfully";
        } else {
          throw "Coulnd't add feeback due to unknown reason";
        }
      } on FirebaseException catch (e) {
        Logger().w("Firebase Exception: $e");
        snackbarMessage = e.toString();
      } catch (e) {
        Logger().w("Unknown Exception: $e");
        snackbarMessage = e.toString();
      } finally {
        Logger().i(snackbarMessage);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
  }
}
