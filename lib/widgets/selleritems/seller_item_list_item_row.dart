import 'package:flutter/material.dart';
import 'package:wastexchange_mobile/utils/app_theme.dart';
import 'package:wastexchange_mobile/utils/global_utils.dart';
import 'package:wastexchange_mobile/widgets/views/number_error_text_field.dart';
import 'package:wastexchange_mobile/widgets/views/number_text_field.dart';

class SellerItemRow extends Row {
  SellerItemRow(
      {@required this.isEditable,
      @required this.text,
      @required this.hintText,
      @required this.textEditingController,
        @required this.showFieldError})
      : assert(isNotNull(isEditable),
            'A non-null Boolean must be provided to editable'),
        assert(isNotNull(hintText), 'The hint text should not be null'),
        assert(isNotNull(text), 'The text should not be null'),
        assert(textEditingController != null,
            'The text editing controller should not be null'),
        super(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              flex: 3,
              child: Text(text, style: AppTheme.body2),
            ),
            Flexible(
                flex: 1,
                child: isEditable
                    ? (showFieldError ? NumberErrorTextField(textEditingController: textEditingController, hintText: hintText)
                    : NumberTextField(textEditingController: textEditingController, hintText: hintText))
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(hintText, style: AppTheme.body2))),
          ],
        );

  final TextEditingController textEditingController;
  final String text;
  final String hintText;
  final bool isEditable;
  final bool showFieldError;
}
