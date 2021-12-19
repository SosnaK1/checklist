import 'package:auto_route/auto_route.dart';
import 'package:checklist/extension/context_extensions.dart';
import 'package:checklist/presentation/checklists/list/checklists_loader_cubit/cubit/checklists_loader_cubit.dart';
import 'package:checklist/presentation/checklists/list/cubit/checklists_cubit.dart';
import 'package:checklist/presentation/checklists/list/widgets/checklist_list_item.dart';
import 'package:checklist/routing/router.gr.dart';
import 'package:checklist/widgets/checklist_blurred_background_wrapper.dart';
import 'package:checklist/widgets/checklist_loading_indicator.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChecklistsPage extends StatefulWidget {
  @override
  State<ChecklistsPage> createState() => _ChecklistsPageState();
}

class _ChecklistsPageState extends State<ChecklistsPage> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<ChecklistsCubit>(context).loadChecklists();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistsCubit, ChecklistsState>(
      builder: (context, state) {
        return _buildPage(state);
      },
    );
  }

  Widget _buildPage(ChecklistsState state) {
    if (state is ChecklistsLoading) {
      return _buildLoader();
    } else if (state is ChecklistsLoaded) {
      return _buildContent(state);
    } else {
      return _buildError();
    }
  }

  Widget _buildLoader() {
    return const ChecklistBlurredBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: ChecklistLoadingIndicator()),
      ),
    );
  }

  Widget _buildContent(ChecklistsLoaded state) {
    return ChecklistBlurredBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: "add checklist",
          child: const Icon(Icons.add),
          onPressed: () {
            context.router.push(AddChecklistRoute());
          },
        ),
        body: Stack(
          children: [
            _buildList(state),
            BlocBuilder<ChecklistsLoaderCubit, ChecklistsLoaderState>(
              builder: (context, state) {
                if (state is ChecklistsLoaderLoading) {
                  return const Center(
                    child: ChecklistLoadingIndicator(),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildList(ChecklistsLoaded state) {
    return RefreshIndicator(
      color: context.isDarkTheme ? Colors.white : Colors.black,
      onRefresh: () async {
        await BlocProvider.of<ChecklistsLoaderCubit>(context)
            .reloadChecklists();
      },
      child: ListView.builder(
        itemCount: state.groupsWithChecklists.length,
        itemBuilder: (context, index) {
          if (state.groupsWithChecklists[index].checklists.isNotEmpty) {
            return ExpansionTile(
              initiallyExpanded: true,
              title: Text(state.groupsWithChecklists[index].group.name ?? ""),
              children: state.groupsWithChecklists[index].checklists
                  .map(
                    (e) => ChecklistListItem(
                      checklist: e,
                      onPressed: () async {
                        final checklistId = e.id;

                        if (checklistId != null) {
                          final shouldUpdate = await context.router.push(
                            ChecklistDetailsRoute(checklistId: checklistId),
                          );

                          if (shouldUpdate == true) {
                            if (!mounted) return;
                            try {
                              BlocProvider.of<ChecklistsLoaderCubit>(context)
                                  .reloadChecklists();
                            } catch (e) {
                              Fimber.d("BlocProvider error");
                            }
                          }
                        }
                      },
                    ),
                  )
                  .toList(),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildError() {
    return const Scaffold(
      body: Center(child: Text("Error loading list, try again later!")),
    );
  }
}
