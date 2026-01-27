import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../providers/app_providers.dart';
import '../widgets/task_card.dart';
import '../models/evento.dart';
import 'task_form_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/voice_service.dart';
import '../widgets/proposal_dialog.dart';

class TareasScreen extends ConsumerWidget {
  const TareasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    // Tareas sin fecha, con filtros y ordenación
    List<Widget> buildTaskList() {
      final filters = ref.watch(eventFilterProvider);
      // Solo tareas sin fecha (ya filtradas en getAllTareas)
      var backlog = tasks;

      // Filtrar por categoría si está seleccionada
      if (filters.selectedCategory != null && filters.selectedCategory!.isNotEmpty) {
        backlog = backlog.where((e) => e.categoria == filters.selectedCategory).toList();
      }

      // Ordenar
      if (filters.sortBy == 'category') {
        backlog.sort((a, b) => (a.categoria ?? '').compareTo(b.categoria ?? ''));
      } else {
        backlog.sort((a, b) => a.titulo.compareTo(b.titulo));
      }

      // Agrupar por tareas principales y subtareas (ejemplo: parentId)
      final principales = backlog.where((t) => t.parentId == null && !t.completada).toList();
      final completadas = backlog.where((t) => t.parentId == null && t.completada).toList();
      final subtareasMap = <String, List<Evento>>{};
      for (final sub in backlog.where((t) => t.parentId != null)) {
        subtareasMap.putIfAbsent(sub.parentId!, () => []).add(sub);
      }

      if (backlog.isEmpty) return [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay tareas pendientes')))] ;

      List<Widget> widgets = [];
      // Tareas pendientes
      widgets.addAll(principales.map((t) => TaskCard(
        tarea: t,
        subtareas: (subtareasMap[t.id] ?? []).where((s) => s.completada == false).toList(),
        onToggle: (_) => ref.read(tasksProvider.notifier).toggleTarea(t.id),
        onTap: (tarea) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskFormScreen(tarea: tarea),
            ),
          );
        },
      )));

      // Sección completadas
      bool showCompletedSection = false;
      widgets.add(
        StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('Completadas', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: Icon(showCompletedSection ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => showCompletedSection = !showCompletedSection),
                ),
              ),
              if (showCompletedSection)
                ...completadas.map((t) => TaskCard(
                  tarea: t,
                  subtareas: (subtareasMap[t.id] ?? []).where((s) => s.completada == true).toList(),
                  onToggle: (_) => ref.read(tasksProvider.notifier).toggleTarea(t.id),
                  onTap: (tarea) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskFormScreen(tarea: tarea),
                      ),
                    );
                  },
                )),
            ],
          ),
        ),
      );

      return widgets;
    }

    // final filters = ref.watch(eventFilterProvider); // Eliminado: no se usa
    final categories = tasks.where((e) => e.categoria != null).map((e) => e.categoria!).toSet().toList()..sort();
    TextEditingController searchController = TextEditingController();
    String searchQuery = '';
    final voiceService = VoiceService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Añadir por voz',
            onPressed: () async {
              var status = await Permission.microphone.status;
              if (!status.isGranted) {
                status = await Permission.microphone.request();
                if (!status.isGranted) return;
              }
              final localContext = context;
              final initialized = await voiceService.initialize();
              if (!localContext.mounted) return;
              if (!initialized) {
                ScaffoldMessenger.of(localContext).showSnackBar(const SnackBar(content: Text('No se pudo inicializar reconocimiento de voz')));
                return;
              }
              String recognizedText = "";
              bool isListening = false;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      if (!isListening) {
                        isListening = true;
                        voiceService.startListening(
                          onResult: (text) {
                            setState(() => recognizedText = text);
                          },
                          onListeningStateChanged: (listening) {
                            if (!listening) {
                              isListening = false;
                              if (Navigator.canPop(dialogContext)) {
                                Navigator.pop(dialogContext);
                              }
                              if (recognizedText.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (_) => ProposalDialog(text: recognizedText),
                                );
                              }
                            }
                          },
                        );
                      }
                      return AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mic, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(recognizedText.isEmpty ? 'Escuchando...' : recognizedText, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                voiceService.stopListening();
                              },
                              child: const Text('Detener'),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ).then((_) {
                if (isListening) {
                  voiceService.stopListening();
                  isListening = false;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return Consumer(
                    builder: (context, dialogRef, _) {
                      final filters = dialogRef.watch(eventFilterProvider);
                      return AlertDialog(
                        title: const Text('Filtros'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                children: [
                                  ...categories.map((c) => FilterChip(
                                    label: Text(c),
                                    selected: filters.selectedCategory == c,
                                    onSelected: (_) => dialogRef.read(eventFilterProvider.notifier).setCategory(filters.selectedCategory == c ? null : c),
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              dialogRef.read(eventFilterProvider.notifier).clear();
                            },
                            child: const Text('Limpiar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar tareas, tags o urgencia...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    onChanged: (v) {
                      searchQuery = v;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.search),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) async {
                  await ref.read(tasksProvider.notifier).reorderTareas(oldIndex, newIndex);
                },
                children: [
                  for (final w in buildTaskList().where((widget) {
                    if (searchQuery.isEmpty) return true;
                    final tarea = (widget is TaskCard) ? widget.tarea : null;
                    if (tarea == null) return true;
                    final tags = tarea.notas ?? '';
                    final urgencia = tarea.categoria ?? '';
                    return tarea.titulo.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        tags.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        urgencia.toLowerCase().contains(searchQuery.toLowerCase());
                  }))
                    Container(key: ValueKey(w.hashCode), child: w),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tareas_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(initialNoDate: true),
            ),
          );
        },
        child: const Icon(Icons.add_task),
      ),
    );
  }
}
