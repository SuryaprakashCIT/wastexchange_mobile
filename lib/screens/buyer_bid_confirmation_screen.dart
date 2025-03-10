import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:wastexchange_mobile/blocs/buyer_bid_confirmation_bloc.dart';
import 'package:wastexchange_mobile/models/bid_item.dart';
import 'package:wastexchange_mobile/models/result.dart';
import 'package:wastexchange_mobile/models/user.dart';
import 'package:wastexchange_mobile/routes/router.dart';
import 'package:wastexchange_mobile/screens/bid_successful_screen.dart';
import 'package:wastexchange_mobile/utils/app_theme.dart';
import 'package:wastexchange_mobile/utils/constants.dart';
import 'package:wastexchange_mobile/utils/widget_display_util.dart';
import 'package:wastexchange_mobile/widgets/order_form_summary_list.dart';
import 'package:wastexchange_mobile/widgets/order_form_header.dart';
import 'package:wastexchange_mobile/widgets/order_form_total.dart';
import 'package:wastexchange_mobile/widgets/views/home_app_bar.dart';

class BuyerBidConfirmationScreen extends StatefulWidget {
  factory BuyerBidConfirmationScreen({
    @required User seller,
    @required List<BidItem> bidItems,
    @required bool restoreSavedState,
    @required VoidCallback onBackPressed,
  }) {
    ArgumentError.checkNotNull(seller);
    ArgumentError.checkNotNull(bidItems);
    ArgumentError.checkNotNull(restoreSavedState);
    ArgumentError.checkNotNull(onBackPressed);
    // TODO(Sayeed): Simplify the throwing of exceptions.
    if (bidItems.isEmpty) {
      throw Exception('BidItems cannot be empty');
    }
    return BuyerBidConfirmationScreen._(
        seller: seller,
        bidItems: bidItems,
        restoreSavedState: restoreSavedState,
        onBackPressed: onBackPressed);
  }

  const BuyerBidConfirmationScreen._({
    User seller,
    List<BidItem> bidItems,
    bool restoreSavedState,
    VoidCallback onBackPressed,
  })  : _seller = seller,
        _bidItems = bidItems,
        _restoreSavedState = restoreSavedState,
        _onBackPressed = onBackPressed;

  final User _seller;
  final List<BidItem> _bidItems;
  final VoidCallback _onBackPressed;
  final bool _restoreSavedState;

  static const String routeName = '/buyerBidConfirmationScreen';

  @override
  _BuyerBidConfirmationScreenState createState() =>
      _BuyerBidConfirmationScreenState();
}

class _BuyerBidConfirmationScreenState
    extends State<BuyerBidConfirmationScreen> {
  BuyerBidConfirmationBloc _bloc;
  // TODO(Sayeed): Check if this is a design problem that we are having to call a child widget method from parent.
  //Also due to this OrderFormHeaderState is public
  final GlobalKey<OrderFormHeaderState> _keyOrderPickup = GlobalKey();

  void _showMessage(String message) {
    Flushbar(
        forwardAnimationCurve: Curves.ease,
        duration: const Duration(seconds: 2),
        message: message)
      ..show(context);
  }

  @override
  void initState() {
    _bloc = BuyerBidConfirmationBloc(
        items: widget._bidItems, sellerId: widget._seller.id);
    _bloc.bidStream.listen((_snapshot) {
      switch (_snapshot.status) {
        case Status.LOADING:
          showLoadingDialog(context);
          break;
        case Status.ERROR:
          dismissDialog(context);
          _showMessage(Constants.BID_FAILURE_MSG);
          break;
        case Status.COMPLETED:
          dismissDialog(context);
          Router.pushNamed(context, BidSuccessfulScreen.routeName);
          break;
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        text: Constants.TITLE_ORDER_FORM,
        onBackPressed: () {
          _keyOrderPickup.currentState.clearSavedData();
          _keyOrderPickup.currentState.saveData();
          widget._onBackPressed();
          Navigator.pop(context, false);
        },
      ),
      bottomNavigationBar: OrderFormTotal(
        total: _bloc.bidTotal,
        itemsCount: _bloc.items.length,
        onPressed: () {
          final result = _keyOrderPickup.currentState.pickupInfoData();
          // TODO(Sayeed): Can we improve this. Examining the state and doing computations here feels off.
          if (result.status == Status.ERROR) {
            _showMessage(result.message);
            return;
          }
          _bloc.placeBid(result.data);
        },
      ),
      body: SingleChildScrollView(
          child: Column(
        children: <Widget>[
          OrderFormHeader(
              key: _keyOrderPickup,
              restoreSavedData: widget._restoreSavedState),
          Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: const Text('Order Summary', style: AppTheme.title)),
          OrderFormSummaryList(items: _bloc.items),
        ],
      )),
    );
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }
}
