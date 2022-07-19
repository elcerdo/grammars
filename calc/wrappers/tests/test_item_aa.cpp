#include <catch2/catch.hpp>

#include <memory>

#include <spdlog/spdlog.h>

template<typename Item>
struct WrapperBase {
  using RawItem = Item*;
  using DeallocItem = std::function<void(RawItem)>;
  using MaybeItem = std::unique_ptr<Item, DeallocItem>;

  using AllocItem = std::function<RawItem(void)>;

  WrapperBase() {
    const auto aa = static_cast<AllocItem>(Item::alloc);
    const auto bb = static_cast<DeallocItem>(Item::dealloc);
    maybe_item = MaybeItem(aa(), bb);
  }

  MaybeItem maybe_item = nullptr;
};

struct ItemAA {
  ItemAA() {
    spdlog::debug("ItemAA()");
  };

  int xx;
  float yy;

  static ItemAA* alloc() {
    spdlog::debug("alloc()");
    return new ItemAA();
  }

  static void dealloc(ItemAA* xx) {
    spdlog::debug("dealloc()");
    if (xx) delete xx;
  }
};



TEST_CASE("Testing ItemAA") {
  using WrapperItemAA = WrapperBase<ItemAA>;

  WrapperItemAA xx;

  REQUIRE(xx.maybe_item);
}
