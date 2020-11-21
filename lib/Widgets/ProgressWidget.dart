import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


circularProgress() {

  return Container(

    alignment: Alignment.center,
    padding: EdgeInsets.only(top: ScreenUtil().setSp(10)),
    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white),),
  );

}

linearProgress() {

  return Container(

    alignment: Alignment.center,
    padding: EdgeInsets.only(top: ScreenUtil().setSp(10)),
    child: LinearProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white),),
  );
}

