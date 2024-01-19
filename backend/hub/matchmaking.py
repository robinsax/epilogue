from .common import pick_implementation

class Matchmaker:

    def match(self, queue: list) -> list[list]:
        raise NotImplementedError()

class SimpleMatchmaker:

    def match(self, queue: list) -> list[list]:
        matched = list()

        while len(queue) >= 2:
            matched.append(list((queue.pop(), queue.pop())))

        return matched

def get_matchmaker() -> Matchmaker:
    impl = pick_implementation('MATCHMAKER', {
        'simple': SimpleMatchmaker
    })

    return impl()
