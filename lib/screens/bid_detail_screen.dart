import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wastexchange_mobile/blocs/bid_detail_bloc.dart';
import 'package:wastexchange_mobile/blocs/map_bloc.dart';
import 'package:wastexchange_mobile/blocs/sellert_Item_bloc.dart';
import 'package:wastexchange_mobile/models/bid.dart';
import 'package:wastexchange_mobile/models/bid_item.dart';
import 'package:wastexchange_mobile/models/item.dart';
import 'package:wastexchange_mobile/models/result.dart';
import 'package:wastexchange_mobile/models/seller_info.dart';
import 'package:wastexchange_mobile/models/seller_item_details_response.dart';
import 'package:wastexchange_mobile/models/user.dart';
import 'package:wastexchange_mobile/routes/router.dart';
import 'package:wastexchange_mobile/screens/bid_edit_item_list.dart';
import 'package:wastexchange_mobile/screens/bid_info.dart';
import 'package:wastexchange_mobile/screens/buyer_bid_confirmation_screen.dart';
import 'package:wastexchange_mobile/screens/seller_item_screen.dart';
import 'package:wastexchange_mobile/utils/app_colors.dart';
import 'package:wastexchange_mobile/utils/constants.dart';
import 'package:wastexchange_mobile/utils/widget_display_util.dart';
import 'package:wastexchange_mobile/widgets/views/button_view.dart';
import 'package:wastexchange_mobile/widgets/views/home_app_bar.dart';

class BidDetailScreen extends StatefulWidget {

  BidDetailScreen({this.bid}) {
    ArgumentError.checkNotNull(bid);
  }

  final Bid bid;

  @override
  State<StatefulWidget> createState() => _BidDetailScreenState(bid: bid);

  static const routeName = '/bidDetailScreen';
}

class _BidDetailScreenState extends State<BidDetailScreen> with SellerItemListener {

  _BidDetailScreenState({this.bid});

  BidDetailBloc _bloc;
  SellerItemBloc _sellerItemBloc;
  bool isEditMode = false;
  SellerItemDetails sellerItemDetails;
  bool _isCancelOperation = false;
  Bid bid;
  User seller;

  List<TextEditingController> _quantityTextEditingControllers;
  List<TextEditingController> _priceTextEditingControllers;

  @override
  void initState() {
    _bloc = BidDetailBloc();

    _bloc.sellerStream.listen((_snapshot) {
      switch (_snapshot.status) {
        case Status.LOADING:
          showLoadingDialog(context);
          break;
        case Status.ERROR:
          dismissDialog(context);
          break;
        case Status.COMPLETED:

          sellerItemDetails = _snapshot.data;

          _bloc.getUser(sellerItemDetails.sellerId).then((result) {

            dismissDialog(context);

            setState(() {

              if(result.status == Status.COMPLETED && result.data != null) {
                seller = result.data;

                _bloc.sortSellerItemsBasedOnBid(sellerItemDetails, bid);

                _sellerItemBloc = SellerItemBloc(this, SellerInfo(seller: seller, items: sellerItemDetails.items));
                _quantityTextEditingControllers =
                    sellerItemDetails.items.map((_) => TextEditingController()).toList();
                _priceTextEditingControllers =
                    sellerItemDetails.items.map((_) => TextEditingController()).toList();

                for(int i=0; i<sellerItemDetails.items.length; i++) {
                  final Item item = sellerItemDetails.items[i];
                  Item bidItem = bid.bidItems[item.name];

                  if(bidItem != null) {
                    _quantityTextEditingControllers[i].text = bidItem.qty.toString();
                    _priceTextEditingControllers[i].text = bidItem.price.toString();
                  }
                }
              }
            });
          });
          break;
      }
    });
    _bloc.bidStream.listen((_snapshot) {
      switch (_snapshot.status) {
        case Status.LOADING:
          showLoadingDialog(context);
          break;
        case Status.ERROR:
          print(_snapshot.message);
          dismissDialog(context);
          if(_isCancelOperation) {
            _isCancelOperation = false;
          }
          break;
        case Status.COMPLETED:
          dismissDialog(context);
          setState(() {
            if(_isCancelOperation) {
              _isCancelOperation = false;
              bid.status = BidStatus.cancelled;
            }
          });
          break;
      }
    });

    _bloc.getSellerDetails(bid.sellerId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(bid != null && sellerItemDetails != null) {
      return showBidDetails();
    } else {
      return emptyView();
    }

  }

  bool isPendingBid() {
    return bid.status == BidStatus.pending;
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  Widget getSubmitAndCancelButtons() {
    return Row(children: <Widget>[
      ButtonView(
          onButtonPressed: () {
            setState(() {
              isEditMode = false;
            });
          },
          buttonStyle: getSmallButtonStyle(),
          text: Constants.BUTTON_CANCEL),
      ButtonView(
          onButtonPressed: () {
            _sellerItemBloc.onSubmitBids(_quantityValues(), _priceValues());
          },
          buttonStyle: getSmallButtonStyle(),
          text: Constants.BUTTON_SUBMIT)
    ]);
  }

  Widget getEditAndCancelBidButtons() {
    return Row(children: <Widget>[
      ButtonView(
        onButtonPressed: () {
          askCancelConfirmation();
        },
        buttonStyle: getSmallButtonStyle(),
        text: Constants.BUTTON_CANCEL_BID,),
      ButtonView(
          onButtonPressed: () {
            setState(() {
              isEditMode = true;
            });
          },
          buttonStyle: getSmallButtonStyle(),
          text: Constants.BUTTON_EDIT_BID)
    ]);
  }

  void askCancelConfirmation() {
    showConfirmationDialog(context, "Cancel Bid", "Are you sure, You want to cancel the bid", "Yes", "No", (status) {
      if(status) {
        _isCancelOperation = true;
        _bloc.cancelBid(bid, sellerItemDetails);
      }
    });
  }

  Widget showBidDetails() {

    return Scaffold(
        bottomNavigationBar: isPendingBid()? isEditMode ? getSubmitAndCancelButtons() : getEditAndCancelBidButtons() : Row(),
        backgroundColor: AppColors.chrome_grey,
        appBar: HomeAppBar(
            text: 'Order Id : ${bid.orderId}',
            onBackPressed: () {
              Navigator.pop(context, false);
            }),
        body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: getEditItemView(isEditMode)));
  }

  Widget emptyView() {
    return Scaffold(
        backgroundColor: AppColors.chrome_grey,
        appBar: HomeAppBar(
            text: 'Order Id : ${bid.orderId}',
            onBackPressed: () {
              Navigator.pop(context, false);
            }),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ));
  }

  Widget getEditItemView(bool isEditMode) {

    return CustomScrollView(slivers: <Widget>[
      SliverList(delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        return BidInfo(bid: bid);
      }, childCount: 1)),
      BidEditItemList(
        bidItems: sellerItemDetails.items.map((item) => BidItem(item: item)).toList(),
        quantityEditingControllers: _quantityTextEditingControllers,
        priceEditingControllers: _priceTextEditingControllers,
        isEditable: isEditMode,)
    ]);
  }

  List<String> _quantityValues() => _quantityTextEditingControllers
      .map((textEditingController) => textEditingController.text)
      .toList();

  List<String> _priceValues() => _priceTextEditingControllers
      .map((textEditingController) => textEditingController.text)
      .toList();

  @override
  void onValidationSuccess({Map<String, dynamic> sellerInfo}) {
    sellerInfo['previousBid'] = bid;
    Router.pushNamed(context, BuyerBidConfirmationScreen.routeName,
        arguments: sellerInfo);
  }

  void showErrorMessage(String message) {
    Flushbar(
        forwardAnimationCurve: Curves.ease,
        duration: Duration(seconds: 2),
        message: message)
      ..show(context);
  }

  @override
  void onValidationError(String message) {
    showErrorMessage(message);
  }

  @override
  void onValidationEmpty(String message) {
    showErrorMessage(message);
  }
}
