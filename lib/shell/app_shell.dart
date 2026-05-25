import 'package:flutter/material.dart';

import 'app_module.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.selectedModule,
    required this.onModuleChanged,
    required this.child,
  });

  final AppModule selectedModule;
  final ValueChanged<AppModule> onModuleChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (!isWide) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE3E8EF))),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppModule.values
                        .map(
                          (module) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: selectedModule == module,
                              avatar: Icon(module.icon, size: 17),
                              label: Text(module.label),
                              onSelected: (_) => onModuleChanged(module),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Expanded(child: _ModuleContent(child: child)),
            ],
          );
        }

        return Row(
          children: [
            Container(
              width: 220,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE3E8EF))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '功能区',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...AppModule.values.map(
                    (module) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NavItem(
                        module: module,
                        selected: selectedModule == module,
                        onTap: () => onModuleChanged(module),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _ModuleContent(child: child)),
          ],
        );
      },
    );
  }
}

class _ModuleContent extends StatelessWidget {
  const _ModuleContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final AppModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFC9E7E1) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              module.icon,
              size: 19,
              color: selected
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF667085),
            ),
            const SizedBox(width: 10),
            Text(
              module.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? const Color(0xFF0F514A)
                    : const Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
