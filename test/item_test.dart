import 'package:bidly/models/item.dart';
import 'package:flutter_test/flutter_test.dart';

Item make({DateTime? end, int bids = 0, bool bought = false, int high = 5000}) => Item(
      id: 'x',
      sellerId: 's',
      sellerName: 'S',
      title: 't',
      description: 'd',
      startingPrice: 5000,
      highestBid: high,
      bidCount: bids,
      boughtNow: bought,
      endTime: end ?? DateTime.now().add(const Duration(hours: 1)),
    );

void main() {
  test('open item', () {
    final i = make();
    expect(i.isClosed, false);
    expect(i.isSold, false);
    expect(i.isUnsold, false);
    expect(i.timeLeft > Duration.zero, true);
    expect(i.minimumBid, 5000 + Item.bidIncrement);
  });
  test('ended with bids is sold, without is unsold', () {
    final past = DateTime.now().subtract(const Duration(minutes: 1));
    expect(make(end: past, bids: 2).isSold, true);
    expect(make(end: past).isUnsold, true);
    expect(make(end: past).timeLeft, Duration.zero);
  });
  test('bought now is closed and sold', () {
    final i = make(bought: true);
    expect(i.isClosed, true);
    expect(i.isSold, true);
  });
}
